/* Copyright 2026 Russell Allen.
   See the LICENSE file for license information. */

// webplugin.cpp -- the Self web (browser) Morphic backend as an oop-library.
//
// A port of the web-backend branch's in-VM backend (vm64/src/any/os/
// webWindow.{hh,cpp} + webPrims) to a runtime-loadable plugin: an embedded
// civetweb HTTP+WebSocket server ships a compact binary opcode stream to an
// HTML5-canvas client (web_client.hh) and queues browser input for the Self
// side to poll.  Differences from the in-VM original:
//
//  - No VM symbols.  The generated glue prims (_WebWindow_*) are replaced by
//    the flat extern "C" exports at the bottom, called from Self through
//    _Dlopen:/_FctLookup:/_Call:With:... (see vm-plugins/include/api.md in the
//    self64 tree).  Windows are identified by their small-integer window id
//    instead of sealed proxies.
//  - No AbstractPlatformWindow.  The VM-Spy rendering path (the low-level
//    draw_*/set_color(long) surface and the monitorWindow/selfMonitor hooks)
//    is dropped; only the ctx_* opcode surface Self actually uses remains.
//  - The per-window wake pipe (written but never read by the VM) is replaced
//    by the plugin ABI's mail doorbell: enqueue/add_pan ring self_raise_flag()
//    on their queue's empty -> non-empty edge.
//  - check_web_events() (a 30 Hz VM poll that shipped frames emitted outside
//    a begin/end-draw bracket) is gone: the two out-of-band emitters,
//    put_scrap and register_font's measure request, ship their frame
//    themselves.
//
// Threading is unchanged: civetweb's workers and the per-server flush thread
// live entirely inside this library, touch only mutexed plugin state, and
// never call into the VM (self_raise_flag is the documented exception).  VM
// timer signals are blocked on all of them.

/* system headers before selfLib.h (poison wall) */
# include <pthread.h>
# include <signal.h>
# include <stdio.h>
# include <stdlib.h>
# include <string.h>
# include <stdint.h>
# include <unistd.h>
# include <sys/time.h>

extern "C" {
# include "civetweb.h"
}

# include "selfLib.h"

typedef uint8_t  uint8;
typedef uint16_t uint16;
typedef uint32_t uint32;
typedef int16_t  int16;

# define WEB_LIB 1            /* web_client.hh keeps its in-VM guard */
# include "web_client.hh"

struct mg_context;
struct mg_connection;


// ======================================================================
// Binary opcode protocol (C++ emits -> web_client.hh consumes).
// Coordinates i16, sizes u16, colours r/g/b u8.  Top-left / y-down, matching
// the canvas (no flip).  Keep in lock-step with web_client.hh.
// ======================================================================
enum WBOp {
    WB_CLEAR_RECT     = 0x01,   // x,y i16  w,h u16
    WB_FILL_RECT      = 0x02,   // x,y i16  w,h u16
    WB_STROKE_RECT    = 0x03,   // x,y i16  w,h u16
    WB_DRAW_LINE      = 0x04,   // x1,y1,x2,y2 i16
    WB_DRAW_TEXT      = 0x05,   // x,y i16  len u16  utf8   (y = baseline)
    WB_SET_COLOR      = 0x06,   // r,g,b u8
    WB_SET_LINE_WIDTH = 0x07,   // w u16
    WB_SET_FONT       = 0x09,   // px u16  bold u8  italic u8  famLen u8  cssFamily
    WB_SET_OP         = 0x0C,   // op u8  (0 copy/source-over, 1 xor)
    WB_SET_CLIP       = 0x0D,   // x,y i16  w,h u16
    WB_CLEAR_CLIP     = 0x0E,
    WB_DRAW_POINT     = 0x0F,   // x,y i16
    WB_SET_ALPHA      = 0x10,   // a u8 (0..255)
    WB_BEGIN_PATH     = 0x11,
    WB_MOVE_TO        = 0x12,   // x,y i16
    WB_LINE_TO        = 0x13,   // x,y i16
    WB_CURVE_TO       = 0x14,   // c1x,c1y,c2x,c2y,x,y i16
    WB_CLOSE_PATH     = 0x16,
    WB_FILL           = 0x17,
    WB_STROKE         = 0x18,
    WB_ARC            = 0x15,   // x,y i16 w,h u16 a1,a2 i16 fill u8 (X 1/64-deg)
    WB_POLYLINE       = 0x1A,   // n u16  (x,y i16)*
    WB_FILL_POLY      = 0x1B,   // n u16  (x,y i16)*
    WB_DRAW_IMAGE     = 0x60,   // imgId u16 sx,sy i16 w,h u16 dx,dy i16
    WB_DEFINE_IMAGE   = 0x61,   // imgId u16 w,h u16  rgba bytes
    WB_MEASURE_FONT   = 0x62,   // fontId u16  bold u8  italic u8  famLen u8  family  (ask browser to measure)
    WB_CREATE_WINDOW  = 0x80,   // id u16 x,y i16 w,h u16 titleLen u8 title
    WB_CLOSE_WINDOW   = 0x81,   // id u16
    WB_RESIZE_WINDOW  = 0x82,   // id u16 w,h u16
    WB_MOVE_WINDOW    = 0x83,   // id u16 x,y i16
    WB_WINDOW_TITLE   = 0x84,   // id u16 len u8 title
    WB_MAP_WINDOW     = 0x85,   // id u16
    WB_UNMAP_WINDOW   = 0x86,   // id u16
    WB_CREATE_PIXMAP  = 0x90,   // id u16 w,h u16
    WB_FREE_PIXMAP    = 0x91,   // id u16
    WB_COPY_AREA      = 0x92,   // srcId u16 sx,sy i16 w,h u16 dx,dy i16
    WB_SET_TARGET     = 0x95,   // id u16  (drawable to draw into)
    WB_SET_CLIPBOARD  = 0x93,   // len u16  utf8   (Self copied -> write the browser/OS clipboard)
    WB_GOING_AWAY     = 0xFE,   // (no payload)  VM is shutting down cleanly -- the client should switch from auto-retry to a manual "Self stopped" state instead of looping a countdown that will fail.  Broadcast from BrowserServer::stop() just before mg_stop tears the sockets down.
    WB_END_FRAME      = 0xFF
};

// Input event types (browser -> C++).  Message: [winId u16][type u8][payload].
enum WBEvt {
    WBE_MOUSE_DOWN = 1,   // x,y i16  button u8  state u8
    WBE_MOUSE_UP   = 2,   // x,y i16  button u8  state u8
    WBE_MOUSE_MOVE = 3,   // x,y i16  state u8
    WBE_KEY_DOWN   = 4,   // keysym u32  char u32  state u8
    WBE_KEY_UP     = 5,   // keysym u32  char u32  state u8
    WBE_SCROLL     = 6,   // x,y i16  dy i16  state u8
    WBE_RESIZE     = 7,   // w,h u16
    WBE_CLOSE      = 8,
    WBE_HEARTBEAT  = 9,   // inbound only: liveness ping, no payload, not enqueued
    WBE_REDRAW_REQ = 10,  // inbound only: client asks for a full redraw, not enqueued
    WBE_PAN        = 11,  // inbound only: dx,dy i16 world-unit view-pan delta; accumulated, not enqueued
    WBE_FONT_TABLE = 12   // inbound only: fontId u16 + 95 adv u16 + asc u16 + desc u16; cached in C++
};


// --- Growable binary command buffer: drawing opcodes for one frame. ---
class CommandBuffer {
    uint8*  _buf;
    uint32  _cap, _size, _baseSize;
    void ensure(uint32 n) {
        if (_size + n <= _cap) return;
        uint32 ncap = _cap ? _cap : 256;
        while (_size + n > ncap) ncap *= 2;
        _buf = (uint8*)realloc(_buf, ncap);
        _cap = ncap;
    }
 public:
    CommandBuffer() : _buf(NULL), _cap(0), _size(0), _baseSize(0) {}
    ~CommandBuffer() { free(_buf); }
    void prealloc(uint32 n) { ensure(n); }
    void reset()       { _size = 0; _baseSize = 0; }
    void resetToBase() { _size = _baseSize; }
    void markBase()    { _baseSize = _size; }
    const uint8* data() const { return _buf; }
    uint32 size() const { return _size; }
    void putU8(uint8 v)   { ensure(1); _buf[_size++] = v; }
    void putU16(uint16 v) { ensure(2); memcpy(_buf + _size, &v, 2); _size += 2; }
    void putU32(uint32 v) { ensure(4); memcpy(_buf + _size, &v, 4); _size += 4; }
    void putI16(int16 v)  { ensure(2); memcpy(_buf + _size, &v, 2); _size += 2; }
    void putBytes(const void* d, uint32 n) { ensure(n); memcpy(_buf + _size, d, n); _size += n; }
};


// --- Per-window double buffer of frames awaiting transmission. ---
struct WindowFrameBuffer {
    uint8*  pending; uint32 pending_len, pending_cap;
    uint8*  last;    uint32 last_len,    last_cap;
    bool    dirty;
    WindowFrameBuffer()
      : pending(NULL), pending_len(0), pending_cap(0),
        last(NULL), last_len(0), last_cap(0), dirty(false) {}
    void ensure_capacity(uint32 n) {
        if (n > pending_cap) { pending_cap = n * 2; pending = (uint8*)realloc(pending, pending_cap); }
        if (n > last_cap)    { last_cap    = n * 2; last    = (uint8*)realloc(last,    last_cap); }
    }
};


// --- A queued input event, already decoded to morphic-friendly fields. ---
struct WebEvent {
    int   type;        // WBEvt
    int   x, y;        // window-local coords
    int   button;      // 1..5
    uint32 state;      // modifier bits (1=shift,2=ctrl,4=alt) as sent by client
    uint32 keysym;     // X-style keysym (browser maps DOM key -> keysym)
    uint32 ch;         // unicode char (0 if none)
    int   w, h;        // for resize
};

static const int WEBEVENTQ_SIZE = 512;

class WebWindow;


// ======================================================================
// Embedded civetweb HTTP + WebSocket server (one per port).
// ======================================================================
class BrowserServer {
 public:
    static const int MAX_WINDOWS = 16;
    static const int MAX_CLIENTS = 8;
 private:
    struct mg_context*    _ctx;
    bool                  _running;
    char                  _listen_spec[256];   // civetweb listening_ports spec (the part after "web:")
    struct mg_connection* _ws_conns[MAX_CLIENTS];
    char                  _ws_seat[MAX_CLIENTS][64];   // the seat (URL) each viewer asked for
    long                  _ws_last_seen[MAX_CLIENTS];  // monotonic ms of last inbound
    long                  _ws_last_sent_ms[MAX_CLIENTS];// monotonic ms of last outbound (frame OR heartbeat)
    int                   _ws_count;
    pthread_mutex_t       _conn_mutex;                 // guards _ws_conns/_ws_count/_ws_last_seen/_ws_last_sent_ms
    WindowFrameBuffer     _frames[MAX_WINDOWS];
    pthread_t             _flush_thread;
    volatile bool         _flush_thread_running;
    volatile bool         _dirty_since_keyframe;       // content changed since last keyframe
    pthread_mutex_t       _frame_mutex;
 public:
    BrowserServer(const char* listen_spec);
    ~BrowserServer();
    // listen_spec is a civetweb listening_ports value: a comma list of ip:port / [ipv6]:port /
    // +port (v4+v6) / x<path> (unix socket).  Servers are keyed by it (same spec -> shared).
    static BrowserServer* for_spec(const char* listen_spec);
    static void stop_all_running();      // atexit hook: broadcast WB_GOING_AWAY and shut every server cleanly
    bool start();
    void stop();
    const char* spec() const { return _listen_spec; }
    bool flush_thread_running() const { return _flush_thread_running; }
    void buffer_frame(int windowId, const uint8* data, uint32 len);
    void flush_pending_frames();
    void replay_window_to(class WebWindow* w);     // (re)send one window to its bound viewer
    void add_ws_connection(struct mg_connection* c, const char* seat);
    void remove_ws_connection(struct mg_connection* c);
    void note_activity(struct mg_connection* c);   // bump last-seen on any inbound frame
    void reap_dead_connections();                  // drop clients silent past the timeout
    void send_heartbeats();                        // send a no-op frame to viewers idle >HEARTBEAT_MS so a kill -STOP'd VM (frozen flush thread = no heartbeats) surfaces as a stall on the client
    static const int HEARTBEAT_MS = 5000;          // outbound idle threshold; client times out at ~2.4x this
    void maybe_send_keyframe();                     // periodic full-redraw resync (if changed + connected)
    void on_ws_data(const uint8* data, uint32 len);
    // --- one viewer (connection) per window/hand ---
    bool is_conn_bound(struct mg_connection* c);    // already the viewer of some open window?
    int  pending_connection_count();                // connections with no window yet (need a hand)
    void bind_matching_connection(class WebWindow* w); // bind a viewer already waiting for w's seat
};


// ======================================================================
// WebWindow -- one browser-rendered window/hand.
// ======================================================================
class WebWindow {
    int             _windowId;
    bool            _open;
    struct mg_connection* _conn;   // the one browser viewing this window/hand (NULL = none yet)
    char            _seat[64];     // the seat (URL, e.g. "" or "alice") this hand serves
    int             _left, _top, _width, _height;
    BrowserServer*  _server;

    CommandBuffer   _cmds;            // accumulating frame for this window

    // event queue (written by civetweb threads, read by the VM thread)
    WebEvent        _evq[WEBEVENTQ_SIZE];
    int             _evq_head, _evq_tail;
    pthread_mutex_t _evq_mutex;
    WebEvent        _cur_event;       // last event popped by next_event_type()
    int             _pan_dx, _pan_dy; // accumulated view-pan delta (world units), drained by the VM
    char*           _scrap;           // this seat's clipboard text (null-terminated, malloc'd)

    int             _font_px;
    int             _font_w, _font_h;
    int             _next_pixmap_id;  // pixmap ids start above window ids

 public:
    WebWindow();
    ~WebWindow();

    // --- window lifecycle ---
    // display_name is "web:" + a civetweb listening_ports spec (or a bare spec).
    bool open(const char* display_name, int x, int y, int w, int h,
              const char* window_name, int font_size);
    void close();
    bool is_open()  { return _open; }
    int  left()   { return _left; }
    int  top()    { return _top; }
    int  width()  { return _width; }
    int  height() { return _height; }
    // Record a size the browser reported (it owns the window size); does NOT emit
    // resize opcodes back, unlike change_extent, so it can't fight the browser.
    void note_browser_size(int w, int h) { if (w > 0) _width = w; if (h > 0) _height = h; }
    bool change_extent(int left, int top, int w, int h);
    void request_full_redraw();   // enqueue a resize-at-current-size -> complete repaint (resync)

    int            windowId()  { return _windowId; }
    CommandBuffer& cmds()      { return _cmds; }
    // --- viewer (browser connection) binding: one viewer per window/hand ---
    struct mg_connection* conn()             { return _conn; }
    void   set_conn(struct mg_connection* c) { _conn = c; }
    bool   has_viewer()                      { return _conn != NULL; }
    const char* seat()                       { return _seat; }
    void   set_seat(const char* s)           { strncpy(_seat, s ? s : "", sizeof(_seat)-1); _seat[sizeof(_seat)-1]=0; }
    void   set_seat_len(const char* s, int len);  // Self labels this window's seat (then binds a waiter)
    bool   is_primary()                      { return _windowId == 1; }  // boot hand: never reaped
    BrowserServer* server()    { return _server; }
    void           ship_frame();          // append the accumulated opcodes to the server's pending frame
    void           set_font_px(int px);
    int            text_width(const char* s, int len);

    // event delivery
    void  enqueue(const WebEvent& e);     // called from civetweb thread
    int   events_pending();
    bool  next_event(WebEvent* out);      // pop; false if empty
    bool  peek_event(WebEvent* out);      // copy head; false if empty
    // view pan: accumulated by the civetweb thread, drained (read-and-zero) by the VM
    void  add_pan(int dx, int dy);
    int   take_pan_x();
    int   take_pan_y();
    // clipboard ("scrap"): in-Self copy/paste, and a push to the browser's real clipboard on copy
    char* get_scrap() { return _scrap ? _scrap : (char*)""; }
    void  put_scrap(const char* s, int len);

    // --- event accessors (operate on the popped _cur_event) ---
    int  next_event_type();   // pop next into _cur_event; return type (0 = none)
    int  event_x()      { return _cur_event.x; }
    int  event_y()      { return _cur_event.y; }
    int  event_button() { return _cur_event.button; }
    int  event_state()  { return (int)_cur_event.state; }
    int  event_keysym() { return (int)_cur_event.keysym; }
    int  event_char()   { return (int)_cur_event.ch; }
    int  event_w()      { return _cur_event.w; }
    int  event_h()      { return _cur_event.h; }

    // --- drawing context: emit opcodes into the current target's buffer ---
    // (the morphic web canvas's drawable/gc route here via the exports)
    void ctx_begin_draw();    // make active + SET_TARGET this window
    void ctx_end_draw();      // ship the accumulated frame
    void ctx_set_color(int r, int g, int b);
    void ctx_set_line_width(int w);
    void ctx_set_font(int px, bool bold, bool italic, const char* fam, int len);
    void ctx_set_alpha(int a);
    void ctx_set_clip(int x, int y, int w, int h);
    void ctx_clear_clip();
    void ctx_fill_rect(int x, int y, int w, int h);
    void ctx_stroke_rect(int x, int y, int w, int h);
    void ctx_clear_rect(int x, int y, int w, int h);
    void ctx_draw_line(int x1, int y1, int x2, int y2);
    void ctx_draw_text(const char* s, int len, int x, int y);
    void ctx_draw_point(int x, int y);
    void ctx_begin_path();
    void ctx_move_to(int x, int y);
    void ctx_line_to(int x, int y);
    void ctx_curve_to(int c1x, int c1y, int c2x, int c2y, int x, int y);
    void ctx_close_path();
    void ctx_fill();
    void ctx_stroke();
    void ctx_arc(int x, int y, int w, int h, int a1, int a2, bool fill);
    int  ctx_create_pixmap(int w, int h);   // returns new pixmap id
    void ctx_free_pixmap(int id);
    void ctx_set_target(int id);
    void ctx_copy_area(int src, int sx, int sy, int w, int h, int dx, int dy);
    // load an indexed (paletted) ui2Image into pixmap `id` as RGBA: expand idx[] through
    // the rgb palette pal[] (3 bytes/entry); pixels equal to transparentIdx become alpha 0
    void ctx_define_image(int id, int w, int h,
                          const char* idx, int idxLen,
                          const char* pal, int palLen, int transparentIdx);
    int  ctx_text_width(const char* s, int len);
    // Append a WB_MEASURE_FONT request to this window's frame (used by wf_register_font).
    void emit_measure_font(int id, const char* fam, int famLen, bool bold, bool italic);
};

static void web_store_font_table(int id, const unsigned short* adv95, int asc, int desc);


// ======================================================================
// WebWindow registry (so the civetweb thread can route input to a window)
// ======================================================================
static WebWindow*  the_windows[BrowserServer::MAX_WINDOWS];
static int         the_window_count = 0;
static WebWindow*  the_active_window = NULL;

static WebWindow* window_by_id(int id) {
    for (int i = 0; i < the_window_count; i++)
        if (the_windows[i] && the_windows[i]->windowId() == id) return the_windows[i];
    return NULL;
}


// ======================================================================
// BrowserServer
// ======================================================================
static BrowserServer* the_servers[BrowserServer::MAX_WINDOWS];
static int            the_server_count = 0;

static long web_now_ms() {
    struct timeval tv; gettimeofday(&tv, NULL);
    return (long)tv.tv_sec * 1000L + (long)(tv.tv_usec / 1000);
}

static void* flush_thread_fn(void* arg) {
    sigset_t block; sigfillset(&block);
    pthread_sigmask(SIG_BLOCK, &block, NULL);   // civetweb thread: no VM signals
    BrowserServer* srv = (BrowserServer*)arg;
    int tick = 0, ktick = 0;
    while (srv->flush_thread_running()) {
        usleep(16 * 1000);   // ~60 Hz
        srv->flush_pending_frames();
        srv->send_heartbeats();  // outbound liveness so a kill -STOP'd VM surfaces as stalled on the client (this thread is suspended too, so heartbeats stop arriving)
        // Reap silent connections roughly every 5s (~300 * 16ms) so a half-open
        // socket (Wi-Fi drop, sleep) is dropped promptly instead of lingering.
        if (++tick >= 300) { tick = 0; srv->reap_dead_connections(); }
        // Periodic keyframe (~every 30s) bounds how long any silent divergence can
        // persist on the incremental, non-idempotent canvas; gated so an idle desktop
        // with no viewers costs nothing.
        if (++ktick >= 1875) { ktick = 0; srv->maybe_send_keyframe(); }
    }
    return NULL;
}

BrowserServer::BrowserServer(const char* listen_spec)
  : _ctx(NULL), _running(false),
    _ws_count(0), _flush_thread(0), _flush_thread_running(false),
    _dirty_since_keyframe(false)
{
    strncpy(_listen_spec, listen_spec ? listen_spec : "9876", sizeof(_listen_spec)-1);
    _listen_spec[sizeof(_listen_spec)-1] = 0;
    for (int i = 0; i < MAX_CLIENTS; i++) { _ws_conns[i] = NULL; _ws_seat[i][0] = 0; _ws_last_seen[i] = 0; _ws_last_sent_ms[i] = 0; }
    pthread_mutex_init(&_frame_mutex, NULL);
    pthread_mutex_init(&_conn_mutex, NULL);
}

BrowserServer::~BrowserServer() { stop(); }

BrowserServer* BrowserServer::for_spec(const char* listen_spec) {
    if (!listen_spec || !listen_spec[0]) listen_spec = "9876";
    for (int i = 0; i < the_server_count; i++)
        if (strcmp(the_servers[i]->spec(), listen_spec) == 0) return the_servers[i];
    if (the_server_count >= BrowserServer::MAX_WINDOWS) return NULL;
    BrowserServer* s = new BrowserServer(listen_spec);
    if (!s->start()) { delete s; return NULL; }
    the_servers[the_server_count++] = s;
    return s;
}

static int http_handler(struct mg_connection* conn, void* cbdata) {
    (void)cbdata;
    const struct mg_request_info* ri = mg_get_request_info(conn);
    // Root "/" is a landing page listing the available seats (each window's seat is
    // user/world/display, set by Self); any other path is the canvas client, which reads
    // its seat from its own URL path and attaches to that window.
    if (ri && ri->local_uri && strcmp(ri->local_uri, "/") == 0) {
        char page[8192];
        int n = snprintf(page, sizeof(page),
            "<!doctype html><meta charset=\"utf-8\"><title>Self (web)</title>"
            "<style>body{font:14px/1.6 sans-serif;margin:2em;color:#222}"
            "h2{margin:0} .hint{color:#888} a{display:inline-block;font-family:monospace}</style>"
            "<h2>Self &mdash; available seats</h2>"
            "<p class=hint>each seat is /user/world/display</p>");
        bool any = false;
        for (int i = 0; i < the_window_count && n < (int)sizeof(page) - 256; i++) {
            WebWindow* w = the_windows[i];
            if (w && w->is_open() && w->seat()[0]) {
                n += snprintf(page + n, sizeof(page) - n, "<a href=\"/%s\">/%s</a><br>", w->seat(), w->seat());
                any = true;
            }
        }
        if (!any) n += snprintf(page + n, sizeof(page) - n, "<p class=hint>(no seats provisioned yet)</p>");
        n = (int)strlen(page);
        mg_send_http_ok(conn, "text/html; charset=utf-8", (long long)n);
        mg_write(conn, page, (size_t)n);
        return 200;
    }
    // Non-root: the path is a seat. If no provisioned window carries it, the connection
    // would hang blank, so serve a "not available" page with a link back to the landing.
    const char* uri = (ri && ri->local_uri) ? ri->local_uri : "/";
    const char* sp = uri; while (*sp == '/') sp++;            // strip leading slashes
    char seat[128]; strncpy(seat, sp, sizeof(seat)-1); seat[sizeof(seat)-1] = 0;
    { size_t L = strlen(seat); while (L > 0 && seat[L-1] == '/') seat[--L] = 0; }  // and trailing
    bool found = false;
    for (int i = 0; i < the_window_count; i++) {
        WebWindow* w = the_windows[i];
        if (w && w->is_open() && strcmp(w->seat(), seat) == 0) { found = true; break; }
    }
    if (!found) {
        char safe[128]; size_t j = 0;                        // sanitise the echoed seat
        for (size_t i = 0; seat[i] && j < sizeof(safe)-1; i++) {
            char c = seat[i];
            if ((c>='a'&&c<='z')||(c>='A'&&c<='Z')||(c>='0'&&c<='9')||c=='/'||c=='_'||c=='-'||c=='.') safe[j++] = c;
        }
        safe[j] = 0;
        char page[2048];
        int n = snprintf(page, sizeof(page),
            "<!doctype html><meta charset=\"utf-8\"><title>Self (web)</title>"
            "<style>body{font:14px/1.6 sans-serif;margin:2em;color:#222}.hint{color:#888}"
            "code{background:#f2f2f2;padding:0 .3em;border-radius:3px}</style>"
            "<h2>Seat not available</h2>"
            "<p class=hint>No window is provisioned for <code>/%s</code>.</p>"
            "<p><a href=\"/\">&larr; available seats</a></p>", safe);
        mg_send_http_ok(conn, "text/html; charset=utf-8", (long long)n);
        mg_write(conn, page, (size_t)n);
        return 200;
    }
    const char* body = WEB_CLIENT_HTML;
    size_t bn = strlen(body);
    mg_send_http_ok(conn, "text/html; charset=utf-8", (long long)bn);
    mg_write(conn, body, bn);
    return 200;
}
static int ws_connect_handler(const struct mg_connection* c, void* cb) { (void)c;(void)cb; return 0; }
static void ws_ready_handler(struct mg_connection* c, void* cb) {
    // The page declares its seat in the WS URL (?seat=NAME, from its page URL path);
    // the connection binds to the window serving that seat, so each distinct webpage
    // is a distinct, stable seat on the shared desktop.
    char seat[64]; seat[0] = 0;
    const struct mg_request_info* ri = mg_get_request_info(c);
    if (ri && ri->query_string)
        mg_get_var(ri->query_string, strlen(ri->query_string), "seat", seat, sizeof(seat));
    ((BrowserServer*)cb)->add_ws_connection(c, seat);
}
static int ws_data_handler(struct mg_connection* c, int bits, char* data, size_t len, void* cb) {
    (void)bits;
    BrowserServer* s = (BrowserServer*)cb;
    s->note_activity(c);                       // any inbound frame proves the client is alive
    s->on_ws_data((const uint8*)data, (uint32)len);
    return 1;
}
static void ws_close_handler(const struct mg_connection* c, void* cb) {
    ((BrowserServer*)cb)->remove_ws_connection(const_cast<struct mg_connection*>(c));
}

bool BrowserServer::start() {
    if (_running) return true;
    mg_init_library(MG_FEATURES_WEBSOCKET);
    const char* options[] = {
        // _listen_spec is a civetweb listening_ports value: comma list of port / ip:port /
        // [ipv6]:port / +port (v4+v6) / x<path> (unix socket).
        "listening_ports", _listen_spec, "num_threads", "8",
        // tcp_nodelay: disable Nagle so small interactive frames aren't held back
        // (Nagle + delayed-ACK can add up to ~40ms of latency per frame).
        "tcp_nodelay", "1",
        // Reap idle/half-open sockets in ~60s instead of an hour; the app-level
        // heartbeat (JS sends one every ~10s) keeps live connections from idling out.
        "enable_keep_alive", "no", "websocket_timeout_ms", "60000", NULL
    };
    struct mg_callbacks cb; memset(&cb, 0, sizeof(cb));
    // Block the VM's timer signals around mg_start so civetweb's worker threads
    // inherit the mask and VM itimer/profiler signals never land on them.
    sigset_t block, prev;
    sigemptyset(&block); sigaddset(&block, SIGALRM); sigaddset(&block, SIGVTALRM);
    pthread_sigmask(SIG_BLOCK, &block, &prev);
    _ctx = mg_start(&cb, NULL, options);
    pthread_sigmask(SIG_SETMASK, &prev, NULL);
    if (!_ctx) { fprintf(stderr, "WebServer: could not bind listen spec '%s' (in use / bad address?)\n", _listen_spec); return false; }
    mg_set_request_handler(_ctx, "/", http_handler, this);
    mg_set_websocket_handler(_ctx, "/ws", ws_connect_handler, ws_ready_handler,
                             ws_data_handler, ws_close_handler, this);
    _running = true;
    _flush_thread_running = true;
    pthread_create(&_flush_thread, NULL, flush_thread_fn, this);
    // Hook process exit so a clean Self quit (_Quit, ctrl-D, SIGINT-then-menu) tells
    // every connected viewer we're going down -- otherwise the client would just see
    // the TCP teardown and start its reconnect countdown.  SIGKILL / segfault skip
    // this and fall back to the client's stall detector.
    static bool atexit_registered = false;
    if (!atexit_registered) { atexit(&BrowserServer::stop_all_running); atexit_registered = true; }
    fprintf(stderr, "Web GUI server started, listening on '%s'\n", _listen_spec);
    return true;
}

void BrowserServer::stop_all_running() {
    for (int i = 0; i < the_server_count; i++)
        if (the_servers[i]) the_servers[i]->stop();
}

void BrowserServer::stop() {
    if (!_running) return;
    // Tell every viewer we're going down BEFORE mg_stop tears down sockets, so the
    // client transitions to its "Self stopped -- click Retry" state instead of looping
    // an auto-reconnect countdown. 4 bytes: [winId=0 u16][WB_GOING_AWAY][WB_END_FRAME].
    // Brief sleep gives the kernel a chance to actually push the bytes; without it the
    // socket close that mg_stop triggers can win the race and the client never sees
    // the frame. 50 ms is well under any user-noticeable shutdown latency.
    static const uint8 BYE[4] = { 0x00, 0x00, WB_GOING_AWAY, WB_END_FRAME };
    pthread_mutex_lock(&_conn_mutex);
    for (int i = 0; i < MAX_CLIENTS; i++)
        if (_ws_conns[i]) mg_websocket_write(_ws_conns[i], MG_WEBSOCKET_OPCODE_BINARY,
                                              (const char*)BYE, sizeof(BYE));
    pthread_mutex_unlock(&_conn_mutex);
    usleep(50 * 1000);
    _flush_thread_running = false;
    if (_flush_thread) { pthread_join(_flush_thread, NULL); _flush_thread = 0; }
    if (_ctx) { mg_stop(_ctx); _ctx = NULL; }
    mg_exit_library();
    for (int i = 0; i < MAX_CLIENTS; i++) _ws_conns[i] = NULL;
    _ws_count = 0; _running = false;
}

// Accumulate (append) a draw cycle's opcodes into the window's pending buffer
// rather than replacing it. Rendering is incremental (the canvas is persistent and
// only damaged regions are repainted), so if two draw cycles landed between flushes
// the old "replace" behaviour dropped the first one's changes permanently, leaving
// the display stale. Appending guarantees every incremental update is delivered, in
// order. `data` is opcodes only (no END_FRAME); flush_pending_frames terminates the
// accumulated stream with a single END_FRAME.
void BrowserServer::buffer_frame(int windowId, const uint8* data, uint32 len) {
    if (windowId < 0 || windowId >= MAX_WINDOWS || len == 0) return;
    WindowFrameBuffer& fb = _frames[windowId];
    pthread_mutex_lock(&_frame_mutex);
    // OOM guard: if the flush thread is stalled on a slow client and the backlog has
    // grown huge, drop it (the client is already behind; it will re-sync) rather than
    // grow without bound.
    if (fb.pending_len > 8u * 1024 * 1024) fb.pending_len = 0;
    if (fb.pending_len == 0) {                 // start a fresh frame: [winId u16]
        fb.ensure_capacity(2 + len);
        fb.pending[0] = (uint8)(windowId & 0xFF);
        fb.pending[1] = (uint8)((windowId >> 8) & 0xFF);
        fb.pending_len = 2;
    } else {
        fb.ensure_capacity(fb.pending_len + len);
    }
    memcpy(fb.pending + fb.pending_len, data, len);
    fb.pending_len += len;
    fb.dirty = true;
    _dirty_since_keyframe = true;
    pthread_mutex_unlock(&_frame_mutex);
}

// --- one viewer (browser connection) per window/hand --------------------------------
// A window's frames go only to its bound viewer.  Binding is decided here (server thread)
// and in set_seat_len (VM thread); _conn and the window list are read/written under
// _conn_mutex.  A connection with no window is "pending" until Self provisions a window
// whose seat matches.

bool BrowserServer::is_conn_bound(struct mg_connection* c) {   // caller holds _conn_mutex
    for (int i = 0; i < the_window_count; i++) {
        WebWindow* w = the_windows[i];
        if (w && w->is_open() && w->conn() == c) return true;
    }
    return false;
}
int BrowserServer::pending_connection_count() {                // polled by the VM
    int n = 0;
    pthread_mutex_lock(&_conn_mutex);
    for (int i = 0; i < MAX_CLIENTS; i++)
        if (_ws_conns[i] && !is_conn_bound(_ws_conns[i])) n++;
    pthread_mutex_unlock(&_conn_mutex);
    return n;
}
// Self just labelled w's seat: if a browser is already waiting for that seat (it connected
// before the window was provisioned), bind it now.
void BrowserServer::bind_matching_connection(WebWindow* w) {
    struct mg_connection* c = NULL;
    pthread_mutex_lock(&_conn_mutex);
    if (!w->has_viewer())
        for (int i = 0; i < MAX_CLIENTS; i++)
            if (_ws_conns[i] && !is_conn_bound(_ws_conns[i]) && strcmp(_ws_seat[i], w->seat()) == 0) {
                w->set_conn(_ws_conns[i]); c = _ws_conns[i]; break;
            }
    pthread_mutex_unlock(&_conn_mutex);
    if (c) replay_window_to(w);
}

void BrowserServer::add_ws_connection(struct mg_connection* c, const char* seat) {
    if (!seat) seat = "";
    WebWindow* bound = NULL;
    pthread_mutex_lock(&_conn_mutex);
    bool added = false;
    for (int i = 0; i < MAX_CLIENTS; i++)
        if (_ws_conns[i] == NULL) {
            _ws_conns[i] = c; strncpy(_ws_seat[i], seat, 63); _ws_seat[i][63] = 0;
            _ws_last_seen[i] = web_now_ms(); _ws_last_sent_ms[i] = web_now_ms(); _ws_count++; added = true; break;
        }
    if (!added) { _ws_conns[0] = c; strncpy(_ws_seat[0], seat, 63); _ws_seat[0][63]=0; _ws_last_seen[0] = web_now_ms(); _ws_last_sent_ms[0] = web_now_ms(); }
    // bind to the open window serving THIS seat that has no live viewer (the waiting base
    // hand for seat "", or a hand whose viewer dropped). No match -> pending: the window
    // provisioned later for this seat adopts it via bind_matching_connection.
    for (int i = 0; i < the_window_count; i++) {
        WebWindow* w = the_windows[i];
        if (w && w->is_open() && !w->has_viewer() && strcmp(w->seat(), seat) == 0) { w->set_conn(c); bound = w; break; }
    }
    pthread_mutex_unlock(&_conn_mutex);
    if (bound) replay_window_to(bound);   // rebuild that seat's window for the (re)joined viewer
}
void BrowserServer::remove_ws_connection(struct mg_connection* c) {
    pthread_mutex_lock(&_conn_mutex);
    for (int i = 0; i < MAX_CLIENTS; i++)
        if (_ws_conns[i] == c) { _ws_conns[i] = NULL; _ws_seat[i][0] = 0; _ws_last_seen[i] = 0; _ws_last_sent_ms[i] = 0; _ws_count--; break; }
    // unbind any window that was viewed by c (keep its seat so a reconnect rebinds); the
    // VM reaps orphaned non-base hands.
    for (int i = 0; i < the_window_count; i++) {
        WebWindow* w = the_windows[i];
        if (w && w->conn() == c) w->set_conn(NULL);
    }
    pthread_mutex_unlock(&_conn_mutex);
}
void BrowserServer::note_activity(struct mg_connection* c) {
    pthread_mutex_lock(&_conn_mutex);
    for (int i = 0; i < MAX_CLIENTS; i++)
        if (_ws_conns[i] == c) { _ws_last_seen[i] = web_now_ms(); break; }
    pthread_mutex_unlock(&_conn_mutex);
}
void BrowserServer::reap_dead_connections() {
    long now = web_now_ms();
    struct mg_connection* dead[MAX_CLIENTS]; int nd = 0;
    pthread_mutex_lock(&_conn_mutex);
    for (int i = 0; i < MAX_CLIENTS; i++)
        if (_ws_conns[i] && (now - _ws_last_seen[i] > 45000)) dead[nd++] = _ws_conns[i];
    pthread_mutex_unlock(&_conn_mutex);
    for (int i = 0; i < nd; i++) remove_ws_connection(dead[i]);   // silent >45s: drop it
}
void BrowserServer::maybe_send_keyframe() {
    pthread_mutex_lock(&_conn_mutex);
    int n = _ws_count;
    pthread_mutex_unlock(&_conn_mutex);
    if (n <= 0 || !_dirty_since_keyframe) return;   // no viewer or nothing changed: skip
    _dirty_since_keyframe = false;
    for (int i = 0; i < the_window_count; i++) {     // resync every hand that has a viewer
        WebWindow* w = the_windows[i];
        if (w && w->is_open() && w->has_viewer()) w->request_full_redraw();
    }
}
// Snapshot finalized frames + the connection list, then write OUTSIDE all locks, so a
// slow/blocked socket write can never hold _frame_mutex and stall buffer_frame (the VM
// thread). A write that fails (broken pipe) marks the connection dead and drops it.
// Called only from the flush thread, so it is the sole socket writer.
void BrowserServer::flush_pending_frames() {
    uint8* fbuf[MAX_WINDOWS]; uint32 flen[MAX_WINDOWS]; int fwin[MAX_WINDOWS]; int nf = 0;
    pthread_mutex_lock(&_frame_mutex);
    for (int i = 0; i < MAX_WINDOWS; i++) {
        WindowFrameBuffer& fb = _frames[i];
        if (!fb.dirty) continue;
        fb.dirty = false;
        fb.ensure_capacity(fb.pending_len + 1);
        fb.pending[fb.pending_len] = WB_END_FRAME;          // terminate the accumulated stream
        uint32 sendLen = fb.pending_len + 1;
        memcpy(fb.last, fb.pending, sendLen); fb.last_len = sendLen;   // keep for replay
        uint8* copy = (uint8*)malloc(sendLen);
        if (copy) { memcpy(copy, fb.pending, sendLen); fbuf[nf] = copy; flen[nf] = sendLen; fwin[nf] = i; nf++; }
        fb.pending_len = 0;                                 // begin a fresh accumulation
    }
    pthread_mutex_unlock(&_frame_mutex);
    if (nf == 0) return;

    // Route each window's frame to its own viewer only (_frames[i] is window id i).
    for (int k = 0; k < nf; k++) {
        WebWindow* w = window_by_id(fwin[k]);
        struct mg_connection* c = NULL;
        if (w) { pthread_mutex_lock(&_conn_mutex); c = w->conn(); pthread_mutex_unlock(&_conn_mutex); }
        if (c) { int wr = mg_websocket_write(c, MG_WEBSOCKET_OPCODE_BINARY,
                                    (const char*)fbuf[k], (size_t)flen[k]);
            if (wr <= 0) remove_ws_connection(c);
            else {
                // resetting last_sent suppresses the heartbeat that would otherwise have
                // gone out shortly -- any real frame already proves liveness to the client.
                pthread_mutex_lock(&_conn_mutex);
                for (int j = 0; j < MAX_CLIENTS; j++)
                    if (_ws_conns[j] == c) { _ws_last_sent_ms[j] = web_now_ms(); break; }
                pthread_mutex_unlock(&_conn_mutex);
            }
        }
        free(fbuf[k]);
    }
}
// Emit a 3-byte no-op frame ([winId=0 u16][WB_END_FRAME]) to any viewer we haven't sent
// anything to in HEARTBEAT_MS. The client treats any inbound message as proof of life
// and times out (declareStall) at ~2.4x HEARTBEAT_MS without one, so the banner appears
// even when the VM is suspended (kill -STOP / deadlock) and TCP never tears down.
// Cheap when nothing's due: just a clock read per connection slot.
void BrowserServer::send_heartbeats() {
    static const uint8 NOOP[3] = { 0x00, 0x00, WB_END_FRAME };
    long now = web_now_ms();
    struct mg_connection* due[MAX_CLIENTS]; int nd = 0;
    pthread_mutex_lock(&_conn_mutex);
    for (int i = 0; i < MAX_CLIENTS; i++)
        if (_ws_conns[i] && (now - _ws_last_sent_ms[i] >= HEARTBEAT_MS)) {
            due[nd++] = _ws_conns[i];
            _ws_last_sent_ms[i] = now;   // optimistically advance; reverted by remove on write failure
        }
    pthread_mutex_unlock(&_conn_mutex);
    for (int i = 0; i < nd; i++) {
        int wr = mg_websocket_write(due[i], MG_WEBSOCKET_OPCODE_BINARY, (const char*)NOOP, sizeof(NOOP));
        if (wr <= 0) remove_ws_connection(due[i]);
    }
}
void BrowserServer::replay_window_to(WebWindow* w) {
    // Rebuild ONE window for its (re)joined viewer: re-send its creation, its last frame,
    // and ask the world to repaint it. Routed only to w's own connection.
    if (!w || !w->is_open()) return;
    struct mg_connection* conn = NULL;
    pthread_mutex_lock(&_conn_mutex); conn = w->conn(); pthread_mutex_unlock(&_conn_mutex);
    if (!conn) return;
    int id = w->windowId();

    CommandBuffer cb; cb.prealloc(256);
    cb.putU16((uint16)id);
    cb.putU8(WB_CREATE_WINDOW); cb.putU16((uint16)id);
    cb.putI16((int16)w->left()); cb.putI16((int16)w->top());
    cb.putU16((uint16)w->width()); cb.putU16((uint16)w->height());
    cb.putU8(0);
    cb.putU8(WB_MAP_WINDOW); cb.putU16((uint16)id);
    cb.putU8(WB_END_FRAME);
    mg_websocket_write(conn, MG_WEBSOCKET_OPCODE_BINARY, (const char*)cb.data(), (size_t)cb.size());

    // Snapshot this window's last frame out of the lock, then write outside it so a slow
    // newly-connecting client can't hold _frame_mutex and stall the VM's buffer_frame.
    uint8* copy = NULL; uint32 clen = 0;
    pthread_mutex_lock(&_frame_mutex);
    if (id >= 0 && id < MAX_WINDOWS) {
        WindowFrameBuffer& fb = _frames[id];
        if (fb.last && fb.last_len > 0) {
            copy = (uint8*)malloc(fb.last_len);
            if (copy) { memcpy(copy, fb.last, fb.last_len); clen = fb.last_len; }
        }
    }
    pthread_mutex_unlock(&_frame_mutex);
    if (copy) { mg_websocket_write(conn, MG_WEBSOCKET_OPCODE_BINARY, (const char*)copy, (size_t)clen); free(copy); }

    // Ask the world to repaint this window (full expose) so the viewer sees live content.
    WebEvent e; memset(&e, 0, sizeof(e));
    e.type = WBE_RESIZE; e.w = w->width(); e.h = w->height();
    w->enqueue(e);
}

void BrowserServer::on_ws_data(const uint8* data, uint32 len) {
    if (len < 3) return;
    uint16 winId; memcpy(&winId, data, 2);
    uint8 type = data[2];
    const uint8* p = data + 3; uint32 rem = len - 3;
    WebWindow* w = window_by_id(winId);
    if (!w) return;
    if (type == WBE_HEARTBEAT)  return;                          // liveness only (already noted)
    if (type == WBE_REDRAW_REQ) { w->request_full_redraw(); return; }  // resync request
    if (type == WBE_PAN) {                                       // view-pan delta (world units)
        if (rem < 4) return;
        int dx = (int16)(p[0] | (p[1] << 8));
        int dy = (int16)(p[2] | (p[3] << 8));
        w->add_pan(dx, dy);
        return;
    }
    if (type == WBE_FONT_TABLE) {                                // measured font metrics
        if (rem < 196) return;                                   // id(2) + 95 adv(190) + asc(2) + desc(2)
        int fid = (int)((uint8)p[0] | ((uint8)p[1] << 8));
        unsigned short adv[95];
        for (int i = 0; i < 95; i++) adv[i] = (unsigned short)((uint8)p[2 + i*2] | ((uint8)p[3 + i*2] << 8));
        int asc = (uint8)p[192] | ((uint8)p[193] << 8);
        int desc = (uint8)p[194] | ((uint8)p[195] << 8);
        web_store_font_table(fid, adv, asc, desc);
        w->request_full_redraw();   // repaint so text is re-positioned with the real metrics
        return;
    }
    #define RDI16(o) ((int16)(p[o] | (p[o+1] << 8)))
    #define RDU16(o) ((uint16)(p[o] | (p[o+1] << 8)))
    #define RDU32(o) ((uint32)(p[o] | (p[o+1]<<8) | (p[o+2]<<16) | ((uint32)p[o+3]<<24)))
    WebEvent e; memset(&e, 0, sizeof(e)); e.type = type;
    switch (type) {
    case WBE_MOUSE_DOWN: case WBE_MOUSE_UP:
        if (rem < 6) return;
        e.x = RDI16(0); e.y = RDI16(2); e.button = p[4]; e.state = p[5]; break;
    case WBE_MOUSE_MOVE:
        if (rem < 5) return;
        e.x = RDI16(0); e.y = RDI16(2); e.state = p[4]; break;
    case WBE_KEY_DOWN: case WBE_KEY_UP:
        if (rem < 9) return;
        e.keysym = RDU32(0); e.ch = RDU32(4); e.state = p[8]; break;
    case WBE_SCROLL:
        if (rem < 7) return;
        e.x = RDI16(0); e.y = RDI16(2); e.h = RDI16(4); e.state = p[6]; break;
    case WBE_RESIZE:
        if (rem < 4) return;
        e.w = RDU16(0); e.h = RDU16(2); w->note_browser_size(e.w, e.h); break;
    case WBE_CLOSE: break;
    default: return;
    }
    #undef RDI16
    #undef RDU16
    #undef RDU32
    w->enqueue(e);
}


// ======================================================================
// WebWindow
// ======================================================================
WebWindow::WebWindow()
  : _windowId(0), _open(false), _conn(NULL), _left(0), _top(0), _width(0), _height(0),
    _server(NULL),
    _evq_head(0), _evq_tail(0), _pan_dx(0), _pan_dy(0),
    _font_px(11), _font_w(7), _font_h(13), _next_pixmap_id(1000)
{
    pthread_mutex_init(&_evq_mutex, NULL);
    memset(&_cur_event, 0, sizeof(_cur_event));
    _seat[0] = 0;          // the base/boot hand serves seat "" (the "/" page)
    _scrap = NULL;
    _cmds.prealloc(4096);
}

WebWindow::~WebWindow() { close(); if (_scrap) free(_scrap); }

bool WebWindow::open(const char* display_name, int x, int y, int w, int h,
                     const char* window_name, int font_size) {
    // The display name is "web:" + a civetweb listening_ports spec (comma list of port /
    // ip:port / [ipv6]:port / +port / x<path>).  Everything after "web:" is the spec; an
    // empty or missing spec defaults to port 9876.
    const char* spec = "9876";
    if (display_name && strncmp(display_name, "web:", 4) == 0 && display_name[4]) spec = display_name + 4;
    if (font_size > 0) set_font_px(font_size);
    _server = BrowserServer::for_spec(spec);
    if (!_server) return false;

    if (the_window_count < BrowserServer::MAX_WINDOWS) {
        _windowId = the_window_count + 1;       // ids start at 1
        the_windows[the_window_count++] = this;
    } else {
        return false;                           // registry full: refuse (id 0 would collide with the broadcast pseudo-id)
    }
    _left = x; _top = y; _width = w; _height = h;
    _open = true;
    the_active_window = this;
    // A window's seat is assigned by Self (set_seat_len) after it provisions the hand for
    // a user; a connection binds by matching that seat. The boot/base window keeps seat ""
    // (the "/" page). No seat is adopted from connections here.

    // tell the browser to create + map this window
    CommandBuffer& c = _cmds; c.reset();
    c.putU8(WB_CREATE_WINDOW); c.putU16((uint16)_windowId);
    c.putI16((int16)x); c.putI16((int16)y);
    c.putU16((uint16)w); c.putU16((uint16)h);
    uint8 tl = window_name ? (uint8)strlen(window_name) : 0;
    c.putU8(tl); if (tl) c.putBytes(window_name, tl);
    c.putU8(WB_MAP_WINDOW); c.putU16((uint16)_windowId);
    ship_frame();
    return true;
}

// Self assigns this window's seat (e.g. "alice/1/2") after provisioning its hand for a
// user; then a browser at that URL binds by seat. Also bind a browser already waiting.
void WebWindow::set_seat_len(const char* s, int len) {
    if (len < 0) len = 0;
    if (len > (int)sizeof(_seat) - 1) len = (int)sizeof(_seat) - 1;
    if ((int)strlen(_seat) == len && memcmp(_seat, s, (size_t)len) == 0) return;  // unchanged: skip
    memcpy(_seat, s, len); _seat[len] = 0;
    if (_server) _server->bind_matching_connection(this);
}

void WebWindow::close() {
    if (!_open) return;
    CommandBuffer& c = _cmds; c.reset();
    c.putU8(WB_CLOSE_WINDOW); c.putU16((uint16)_windowId);
    ship_frame();
    _open = false;
}

bool WebWindow::change_extent(int left, int top, int w, int h) {
    _left = left; _top = top; _width = w; _height = h;
    CommandBuffer& c = _cmds;
    c.putU8(WB_MOVE_WINDOW);   c.putU16((uint16)_windowId); c.putI16((int16)left); c.putI16((int16)top);
    c.putU8(WB_RESIZE_WINDOW); c.putU16((uint16)_windowId); c.putU16((uint16)w);  c.putU16((uint16)h);
    return true;
}

void WebWindow::ship_frame() {
    if (_cmds.size() == 0) return;
    if (!_server) { _cmds.reset(); return; }
    // Hand the raw opcodes to the server, which appends them to the pending frame;
    // the terminating END_FRAME is added once per flush, not once per draw cycle.
    _server->buffer_frame(_windowId, _cmds.data(), _cmds.size());
    _cmds.reset();
}

void WebWindow::set_font_px(int px) {
    _font_px = px;
    _font_w = (px * 6) / 10; if (_font_w < 1) _font_w = 1;
    _font_h = px + 2;
}
int WebWindow::text_width(const char* s, int len) {
    (void)s; return _font_w * (len < 0 ? 0 : len);
}

// Resync: enqueue a resize at the current size so the world repaints the whole window
// (full-bounds damage), re-sending every opcode. Reuses the proven reconnect path.
void WebWindow::request_full_redraw() {
    WebEvent e; memset(&e, 0, sizeof(e));
    e.type = WBE_RESIZE; e.w = _width; e.h = _height;
    enqueue(e);
}

// --- events ---
void WebWindow::enqueue(const WebEvent& e) {
    bool was_empty;
    pthread_mutex_lock(&_evq_mutex);
    was_empty = (_evq_head == _evq_tail);
    // Motion compression: the world dispatches only one event per UI step, so if
    // moves arrive faster than it can redraw (e.g. a complex morph on the debug VM)
    // the queue backs up and the morph trails the cursor. When this event is a move
    // and the most recently queued event is also a move, replace it instead of
    // appending -- each step then works toward the latest position (intermediates are
    // dropped) so the morph tracks the mouse. A button/key event breaks the chain,
    // so transitions are never dropped or reordered.
    if (e.type == WBE_MOUSE_MOVE && _evq_head != _evq_tail) {
        int last = (_evq_tail - 1 + WEBEVENTQ_SIZE) % WEBEVENTQ_SIZE;
        if (_evq[last].type == WBE_MOUSE_MOVE) {
            _evq[last] = e;
            pthread_mutex_unlock(&_evq_mutex);
            return;                        // queue was non-empty: a wake-up is already pending
        }
    }
    int next = (_evq_tail + 1) % WEBEVENTQ_SIZE;
    if (next != _evq_head) { _evq[_evq_tail] = e; _evq_tail = next; }
    pthread_mutex_unlock(&_evq_mutex);
    // Ring the mail doorbell on the queue's empty -> non-empty edge (the documented
    // coalescing pattern); thread-safe, callable from the civetweb threads.
    if (was_empty) self_raise_flag();
}
int WebWindow::events_pending() {
    pthread_mutex_lock(&_evq_mutex);
    int n = (_evq_tail - _evq_head + WEBEVENTQ_SIZE) % WEBEVENTQ_SIZE;
    pthread_mutex_unlock(&_evq_mutex);
    return n;
}
// View pan: a separate accumulator (not a queued event) so rapid pans coalesce
// into one offset move. Written by the civetweb thread, drained by the VM.
void WebWindow::add_pan(int dx, int dy) {
    bool was_zero;
    pthread_mutex_lock(&_evq_mutex);
    was_zero = (_pan_dx == 0 && _pan_dy == 0);
    _pan_dx += dx; _pan_dy += dy;
    pthread_mutex_unlock(&_evq_mutex);
    if (was_zero && (dx != 0 || dy != 0)) self_raise_flag();
}
int WebWindow::take_pan_x() {
    pthread_mutex_lock(&_evq_mutex);
    int v = _pan_dx; _pan_dx = 0;
    pthread_mutex_unlock(&_evq_mutex);
    return v;
}
int WebWindow::take_pan_y() {
    pthread_mutex_lock(&_evq_mutex);
    int v = _pan_dy; _pan_dy = 0;
    pthread_mutex_unlock(&_evq_mutex);
    return v;
}
// Store text Self copied into this seat's scrap (so an in-Self paste returns it) and push it
// to the browser, which writes the viewer's real clipboard (navigator.clipboard.writeText).
// Ships its own frame: a copy can happen outside any begin/end-draw bracket, and there is
// no VM-side poll to sweep stragglers up.
void WebWindow::put_scrap(const char* s, int len) {
    if (len < 0) len = 0;
    char* n = (char*)malloc((size_t)len + 1);
    if (!n) return;
    if (len) memcpy(n, s, (size_t)len);
    n[len] = 0;
    if (_scrap) free(_scrap);
    _scrap = n;
    _cmds.putU8(WB_SET_CLIPBOARD); _cmds.putU16((uint16)len);
    if (len) _cmds.putBytes(s, (uint32)len);
    ship_frame();
}
bool WebWindow::next_event(WebEvent* out) {
    bool got = false;
    pthread_mutex_lock(&_evq_mutex);
    if (_evq_head != _evq_tail) { *out = _evq[_evq_head]; _evq_head = (_evq_head + 1) % WEBEVENTQ_SIZE; got = true; }
    pthread_mutex_unlock(&_evq_mutex);
    return got;
}
bool WebWindow::peek_event(WebEvent* out) {
    bool got = false;
    pthread_mutex_lock(&_evq_mutex);
    if (_evq_head != _evq_tail) { *out = _evq[_evq_head]; got = true; }
    pthread_mutex_unlock(&_evq_mutex);
    return got;
}


int WebWindow::next_event_type() {
    if (!next_event(&_cur_event)) { _cur_event.type = 0; return 0; }
    return _cur_event.type;
}


// ======================================================================
// Drawing context -- emit opcodes into this window's command buffer.
// The morphic web canvas's drawable/gc route here via the exports.
// ======================================================================
void WebWindow::ctx_begin_draw() {
    the_active_window = this;
    _cmds.putU8(WB_SET_TARGET); _cmds.putU16((uint16)_windowId);
}
void WebWindow::ctx_end_draw() { ship_frame(); }

void WebWindow::ctx_set_color(int r, int g, int b) {
    _cmds.putU8(WB_SET_COLOR); _cmds.putU8((uint8)r); _cmds.putU8((uint8)g); _cmds.putU8((uint8)b);
}
void WebWindow::ctx_set_line_width(int w) { _cmds.putU8(WB_SET_LINE_WIDTH); _cmds.putU16((uint16)(w < 1 ? 1 : w)); }
void WebWindow::ctx_set_font(int px, bool bold, bool italic, const char* fam, int len) {
    set_font_px(px);
    _cmds.putU8(WB_SET_FONT); _cmds.putU16((uint16)px);
    _cmds.putU8(bold ? 1 : 0); _cmds.putU8(italic ? 1 : 0);
    uint8 fl = (len < 0) ? 0 : (uint8)(len > 255 ? 255 : len);
    _cmds.putU8(fl); if (fl) _cmds.putBytes(fam, fl);
}
void WebWindow::ctx_set_alpha(int a) { _cmds.putU8(WB_SET_ALPHA); _cmds.putU8((uint8)a); }
void WebWindow::ctx_set_clip(int x, int y, int w, int h) {
    _cmds.putU8(WB_SET_CLIP); _cmds.putI16((int16)x); _cmds.putI16((int16)y);
    _cmds.putU16((uint16)w); _cmds.putU16((uint16)h);
}
void WebWindow::ctx_clear_clip() { _cmds.putU8(WB_CLEAR_CLIP); }
void WebWindow::ctx_fill_rect(int x, int y, int w, int h) {
    _cmds.putU8(WB_FILL_RECT); _cmds.putI16((int16)x); _cmds.putI16((int16)y);
    _cmds.putU16((uint16)w); _cmds.putU16((uint16)h);
}
void WebWindow::ctx_stroke_rect(int x, int y, int w, int h) {
    _cmds.putU8(WB_STROKE_RECT); _cmds.putI16((int16)x); _cmds.putI16((int16)y);
    _cmds.putU16((uint16)w); _cmds.putU16((uint16)h);
}
void WebWindow::ctx_clear_rect(int x, int y, int w, int h) {
    _cmds.putU8(WB_CLEAR_RECT); _cmds.putI16((int16)x); _cmds.putI16((int16)y);
    _cmds.putU16((uint16)w); _cmds.putU16((uint16)h);
}
void WebWindow::ctx_draw_line(int x1, int y1, int x2, int y2) {
    _cmds.putU8(WB_DRAW_LINE); _cmds.putI16((int16)x1); _cmds.putI16((int16)y1);
    _cmds.putI16((int16)x2); _cmds.putI16((int16)y2);
}
void WebWindow::ctx_draw_text(const char* s, int len, int x, int y) {
    if (len < 0) len = 0;
    _cmds.putU8(WB_DRAW_TEXT); _cmds.putI16((int16)x); _cmds.putI16((int16)y);
    _cmds.putU16((uint16)len); if (len) _cmds.putBytes(s, (uint32)len);
}
void WebWindow::ctx_draw_point(int x, int y) {
    _cmds.putU8(WB_DRAW_POINT); _cmds.putI16((int16)x); _cmds.putI16((int16)y);
}
void WebWindow::ctx_begin_path() { _cmds.putU8(WB_BEGIN_PATH); }
void WebWindow::ctx_move_to(int x, int y) { _cmds.putU8(WB_MOVE_TO); _cmds.putI16((int16)x); _cmds.putI16((int16)y); }
void WebWindow::ctx_line_to(int x, int y) { _cmds.putU8(WB_LINE_TO); _cmds.putI16((int16)x); _cmds.putI16((int16)y); }
void WebWindow::ctx_curve_to(int c1x, int c1y, int c2x, int c2y, int x, int y) {
    _cmds.putU8(WB_CURVE_TO);
    _cmds.putI16((int16)c1x); _cmds.putI16((int16)c1y);
    _cmds.putI16((int16)c2x); _cmds.putI16((int16)c2y);
    _cmds.putI16((int16)x);   _cmds.putI16((int16)y);
}
void WebWindow::ctx_close_path() { _cmds.putU8(WB_CLOSE_PATH); }
void WebWindow::ctx_fill()   { _cmds.putU8(WB_FILL); }
void WebWindow::ctx_stroke() { _cmds.putU8(WB_STROKE); }
void WebWindow::ctx_arc(int x, int y, int w, int h, int a1, int a2, bool fill) {
    _cmds.putU8(WB_ARC); _cmds.putI16((int16)x); _cmds.putI16((int16)y);
    _cmds.putU16((uint16)w); _cmds.putU16((uint16)h);
    _cmds.putI16((int16)a1); _cmds.putI16((int16)a2); _cmds.putU8(fill ? 1 : 0);
}
int WebWindow::ctx_create_pixmap(int w, int h) {
    int id = _next_pixmap_id++;
    _cmds.putU8(WB_CREATE_PIXMAP); _cmds.putU16((uint16)id); _cmds.putU16((uint16)w); _cmds.putU16((uint16)h);
    return id;
}
void WebWindow::ctx_free_pixmap(int id) { _cmds.putU8(WB_FREE_PIXMAP); _cmds.putU16((uint16)id); }
void WebWindow::ctx_set_target(int id) { _cmds.putU8(WB_SET_TARGET); _cmds.putU16((uint16)id); }
void WebWindow::ctx_copy_area(int src, int sx, int sy, int w, int h, int dx, int dy) {
    _cmds.putU8(WB_COPY_AREA); _cmds.putU16((uint16)src);
    _cmds.putI16((int16)sx); _cmds.putI16((int16)sy);
    _cmds.putU16((uint16)w); _cmds.putU16((uint16)h);
    _cmds.putI16((int16)dx); _cmds.putI16((int16)dy);
}
void WebWindow::ctx_define_image(int id, int w, int h,
                                 const char* idx, int idxLen,
                                 const char* pal, int palLen, int transparentIdx) {
    if (w <= 0 || h <= 0) return;
    int npx = w * h;
    if (idxLen < npx) return;                 // one palette index per pixel
    int npal = palLen / 3;
    _cmds.putU8(WB_DEFINE_IMAGE);
    _cmds.putU16((uint16)id);
    _cmds.putU16((uint16)w); _cmds.putU16((uint16)h);
    for (int i = 0; i < npx; i++) {
        int ci = (unsigned char)idx[i];
        unsigned char r = 0, g = 0, b = 0, a = 255;
        if (ci < npal) { r = (unsigned char)pal[ci*3]; g = (unsigned char)pal[ci*3+1]; b = (unsigned char)pal[ci*3+2]; }
        if (ci == transparentIdx) a = 0;
        _cmds.putU8(r); _cmds.putU8(g); _cmds.putU8(b); _cmds.putU8(a);
    }
}
int WebWindow::ctx_text_width(const char* s, int len) { return text_width(s, len); }


// ======================================================================
// Proportional font metrics.  The browser measures each (family,style) once via
// canvas measureText and sends a per-character advance table (ASCII 32..126) plus
// ascent/descent, all per-em x1000 at a fixed base size.  Stored here by font id;
// widths are summed synchronously and scaled to the requested pixel size.
// (Internal names carry a wf_ prefix; the plain web_* names are the exports.)
// ======================================================================
static const int WEB_MAX_FONTS  = 128;
static const int WEB_FONT_BASE  = 1000;   // ratios are stored as per-em x1000
struct WebFontMetrics {
    bool   calibrated;
    bool   requested;
    unsigned short adv[95];   // advance per-em x1000 for ASCII 32..126
    unsigned short asc, desc; // per-em x1000
};
static WebFontMetrics g_web_fonts[WEB_MAX_FONTS];   // index = Self-assigned font id

// Set when a calibration table arrives so the world can re-measure cached label widths
// (which were computed from the pre-calibration estimate); see the consume export.
static bool g_fonts_relayout = false;

static void web_store_font_table(int id, const unsigned short* adv95, int asc, int desc) {
    if (id < 0 || id >= WEB_MAX_FONTS) return;
    WebFontMetrics& f = g_web_fonts[id];
    for (int i = 0; i < 95; i++) f.adv[i] = adv95[i];
    f.asc = (unsigned short)asc; f.desc = (unsigned short)desc;
    f.calibrated = true;
    g_fonts_relayout = true;
}

void WebWindow::emit_measure_font(int id, const char* fam, int famLen, bool bold, bool italic) {
    _cmds.putU8(WB_MEASURE_FONT); _cmds.putU16((uint16)id);
    _cmds.putU8(bold ? 1 : 0); _cmds.putU8(italic ? 1 : 0);
    _cmds.putU8((uint8)famLen); _cmds.putBytes(fam, (uint32)famLen);
}

static void wf_register_font(int id, const char* fam, int famLen, bool bold, bool italic) {
    if (id < 0 || id >= WEB_MAX_FONTS) return;
    WebFontMetrics& f = g_web_fonts[id];
    if (f.calibrated || f.requested) return;     // measure each font only once
    f.requested = true;
    WebWindow* w = the_active_window;            // the measure request rides the active frame
    if (!w) { f.requested = false; return; }     // retry once a window is active
    if (famLen < 0) famLen = 0; if (famLen > 255) famLen = 255;
    w->emit_measure_font(id, fam, famLen, bold, italic);
    w->ship_frame();   // may run outside a draw bracket, and no VM poll sweeps stragglers
}

static int wf_font_text_width(int id, int size, const char* s, int len) {
    if (len < 0) len = 0;
    if (id < 0 || id >= WEB_MAX_FONTS || !g_web_fonts[id].calibrated)
        return ((size * 6) / 10) * len;          // monospace-ish estimate until calibrated
    const WebFontMetrics& f = g_web_fonts[id];
    // Sum the per-character advance ROUNDED to whole pixels (round-half-up).  The editor
    // measures runs both per-character and merged, and the browser draws each glyph at
    // this same rounded advance (see web_client.hh case 0x05), so width(s) here equals
    // the rendered width exactly and the caret stays aligned with the text.
    long total = 0;
    for (int i = 0; i < len; i++) {
        unsigned char c = (unsigned char)s[i];
        int per = (c >= 32 && c <= 126) ? f.adv[c - 32] : f.adv['n' - 32];  // default = 'n'
        total += (per * size + WEB_FONT_BASE / 2) / WEB_FONT_BASE;
    }
    return (int)total;
}
static int wf_font_ascent(int id, int size) {
    if (id < 0 || id >= WEB_MAX_FONTS || !g_web_fonts[id].calibrated) return (size * 4) / 5;
    return (int)(((long)g_web_fonts[id].asc * size) / WEB_FONT_BASE);
}
static int wf_font_descent(int id, int size) {
    if (id < 0 || id >= WEB_MAX_FONTS || !g_web_fonts[id].calibrated) return (size / 5) + 1;
    return (int)(((long)g_web_fonts[id].desc * size) / WEB_FONT_BASE);
}


// ======================================================================
// The oop-library surface.  Every export takes/returns raw oops (smis for
// ints and 0/1 booleans -- ABI 1.0 has no boolean helpers -- byteVectors for
// strings/bytes) and is called on the VM thread via fct _Call:With:...; the
// Self-side wrappers live in webPlugin.self beside this file.  Window handles
// are the small-integer window ids the C++ side already assigns.
// ======================================================================

const SelfHelpers* self_ctx;

extern "C" int self_lib_init(int vm_abi_major, const SelfHelpers* h) {
  if (vm_abi_major != SELF_PLUGIN_ABI_MAJOR) return -1;
  self_ctx = h;
  return SELF_PLUGIN_ABI_MINOR;
}

typedef self_oop oop;

static bool to_int(oop o, int* v) {
    if (self_is_smi(o))   { *v = (int)self_smi_value(o);     return true; }
    if (self_is_float(o)) { *v = (int)self_float_value(o);   return true; }
    return false;
}
static bool to_str(oop o, const char** p, int* n) {
    intptr_t len = self_bv_length(o);
    if (len < 0) return false;
    const char* b = self_bv_bytes_ro(o);
    if (!b) return false;
    *p = b; *n = (int)len;
    return true;
}

#define FAIL_BADTYPE     return self_error(SELF_ERR_BADTYPE)
#define GET_WIN(o)       WebWindow* w = self_is_smi(o) ? window_by_id((int)self_smi_value(o)) : NULL; \
                         if (!w) FAIL_BADTYPE
#define GET_INT(v, o)    int v; if (!to_int(o, &v)) FAIL_BADTYPE
#define GET_STR(p, n, o) const char* p; int n; if (!to_str(o, &p, &n)) FAIL_BADTYPE
#define DONE             return self_smi(0)

extern "C" {

/* ---- window lifecycle ----------------------------------------------------
 * open takes the display name ('web:' + listen spec, or a bare spec), the
 * initial geometry, the window title, and the default font size; it answers
 * the new window's id (>= 1), the handle every other function takes first. */

oop web_open(oop spec_, oop x_, oop y_, oop w_, oop h_, oop title_, oop fontPx_) {
    GET_STR(sp, sn, spec_); GET_STR(tp, tn, title_);
    GET_INT(x, x_); GET_INT(y, y_); GET_INT(ww, w_); GET_INT(hh, h_); GET_INT(px, fontPx_);
    char spec[256], title[256];                 /* byteVector bytes are not NUL-terminated */
    if (sn > 255) sn = 255;  memcpy(spec, sp, sn);   spec[sn] = 0;
    if (tn > 255) tn = 255;  memcpy(title, tp, tn);  title[tn] = 0;
    WebWindow* w = new WebWindow();
    if (!w->open(spec, x, y, ww, hh, title, px)) {
        delete w;
        return self_error(SELF_ERR_PRIMITIVEFAILED);
    }
    return self_smi(w->windowId());
}

oop web_close(oop w_)      { GET_WIN(w_); w->close(); DONE; }
oop web_is_open(oop w_)    { GET_WIN(w_); return self_smi(w->is_open() ? 1 : 0); }
oop web_left(oop w_)       { GET_WIN(w_); return self_smi(w->left()); }
oop web_top(oop w_)        { GET_WIN(w_); return self_smi(w->top()); }
oop web_width(oop w_)      { GET_WIN(w_); return self_smi(w->width()); }
oop web_height(oop w_)     { GET_WIN(w_); return self_smi(w->height()); }
oop web_set_extent(oop w_, oop l_, oop t_, oop ww_, oop h_) {
    GET_WIN(w_); GET_INT(l, l_); GET_INT(t, t_); GET_INT(ww, ww_); GET_INT(h, h_);
    if (!w->change_extent(l, t, ww, h)) return self_error(SELF_ERR_PRIMITIVEFAILED);
    DONE;
}

/* ---- events (pop-then-read: next_event_type pops into the current event,
 * the accessors read its fields) --------------------------------------- */

oop web_events_pending(oop w_)  { GET_WIN(w_); return self_smi(w->events_pending()); }
oop web_next_event_type(oop w_) { GET_WIN(w_); return self_smi(w->next_event_type()); }
oop web_event_x(oop w_)         { GET_WIN(w_); return self_smi(w->event_x()); }
oop web_event_y(oop w_)         { GET_WIN(w_); return self_smi(w->event_y()); }
oop web_event_button(oop w_)    { GET_WIN(w_); return self_smi(w->event_button()); }
oop web_event_state(oop w_)     { GET_WIN(w_); return self_smi(w->event_state()); }
oop web_event_keysym(oop w_)    { GET_WIN(w_); return self_smi(w->event_keysym()); }
oop web_event_char(oop w_)      { GET_WIN(w_); return self_smi(w->event_char()); }
oop web_event_w(oop w_)         { GET_WIN(w_); return self_smi(w->event_w()); }
oop web_event_h(oop w_)         { GET_WIN(w_); return self_smi(w->event_h()); }
oop web_take_pan_x(oop w_)      { GET_WIN(w_); return self_smi(w->take_pan_x()); }
oop web_take_pan_y(oop w_)      { GET_WIN(w_); return self_smi(w->take_pan_y()); }

/* ---- clipboard.  No allocation across the ABI: Self asks the length, makes
 * a buffer, and has it filled (the scrap only changes on the VM thread, so
 * the two calls cannot race). ------------------------------------------- */

oop web_scrap_length(oop w_) { GET_WIN(w_); return self_smi((intptr_t)strlen(w->get_scrap())); }
oop web_scrap_into(oop w_, oop dst) {
    GET_WIN(w_);
    const char* s = w->get_scrap();
    intptr_t sl = (intptr_t)strlen(s);
    intptr_t cap = self_bv_length(dst);
    if (cap < 0) FAIL_BADTYPE;
    intptr_t n = sl < cap ? sl : cap;
    if (n > 0 && self_bv_copy_in(dst, 0, n, s) < 0) return self_error(SELF_ERR_IMMUTABLE);
    return self_smi(n);
}
oop web_put_scrap(oop w_, oop s_) {
    GET_WIN(w_); GET_STR(p, n, s_);
    w->put_scrap(p, n);
    DONE;
}

/* ---- drawing context ---------------------------------------------------- */

oop web_begin_draw(oop w_) { GET_WIN(w_); w->ctx_begin_draw(); DONE; }
oop web_end_draw(oop w_)   { GET_WIN(w_); w->ctx_end_draw(); DONE; }
oop web_set_color(oop w_, oop r_, oop g_, oop b_) {
    GET_WIN(w_); GET_INT(r, r_); GET_INT(g, g_); GET_INT(b, b_);
    w->ctx_set_color(r, g, b); DONE;
}
oop web_set_line_width(oop w_, oop lw_) {
    GET_WIN(w_); GET_INT(lw, lw_);
    w->ctx_set_line_width(lw); DONE;
}
oop web_set_font(oop w_, oop px_, oop bold_, oop ital_, oop fam_) {
    GET_WIN(w_); GET_INT(px, px_); GET_INT(b, bold_); GET_INT(it, ital_); GET_STR(fp, fn, fam_);
    w->ctx_set_font(px, b != 0, it != 0, fp, fn); DONE;
}
oop web_set_alpha(oop w_, oop a_) {
    GET_WIN(w_); GET_INT(a, a_);
    w->ctx_set_alpha(a); DONE;
}
oop web_set_clip(oop w_, oop x_, oop y_, oop ww_, oop h_) {
    GET_WIN(w_); GET_INT(x, x_); GET_INT(y, y_); GET_INT(ww, ww_); GET_INT(h, h_);
    w->ctx_set_clip(x, y, ww, h); DONE;
}
oop web_clear_clip(oop w_) { GET_WIN(w_); w->ctx_clear_clip(); DONE; }
oop web_fill_rect(oop w_, oop x_, oop y_, oop ww_, oop h_) {
    GET_WIN(w_); GET_INT(x, x_); GET_INT(y, y_); GET_INT(ww, ww_); GET_INT(h, h_);
    w->ctx_fill_rect(x, y, ww, h); DONE;
}
oop web_stroke_rect(oop w_, oop x_, oop y_, oop ww_, oop h_) {
    GET_WIN(w_); GET_INT(x, x_); GET_INT(y, y_); GET_INT(ww, ww_); GET_INT(h, h_);
    w->ctx_stroke_rect(x, y, ww, h); DONE;
}
oop web_clear_rect(oop w_, oop x_, oop y_, oop ww_, oop h_) {
    GET_WIN(w_); GET_INT(x, x_); GET_INT(y, y_); GET_INT(ww, ww_); GET_INT(h, h_);
    w->ctx_clear_rect(x, y, ww, h); DONE;
}
oop web_draw_line(oop w_, oop x1_, oop y1_, oop x2_, oop y2_) {
    GET_WIN(w_); GET_INT(x1, x1_); GET_INT(y1, y1_); GET_INT(x2, x2_); GET_INT(y2, y2_);
    w->ctx_draw_line(x1, y1, x2, y2); DONE;
}
oop web_draw_text(oop w_, oop s_, oop x_, oop y_) {
    GET_WIN(w_); GET_STR(p, n, s_); GET_INT(x, x_); GET_INT(y, y_);
    w->ctx_draw_text(p, n, x, y); DONE;
}
oop web_draw_point(oop w_, oop x_, oop y_) {
    GET_WIN(w_); GET_INT(x, x_); GET_INT(y, y_);
    w->ctx_draw_point(x, y); DONE;
}
oop web_begin_path(oop w_) { GET_WIN(w_); w->ctx_begin_path(); DONE; }
oop web_move_to(oop w_, oop x_, oop y_) {
    GET_WIN(w_); GET_INT(x, x_); GET_INT(y, y_);
    w->ctx_move_to(x, y); DONE;
}
oop web_line_to(oop w_, oop x_, oop y_) {
    GET_WIN(w_); GET_INT(x, x_); GET_INT(y, y_);
    w->ctx_line_to(x, y); DONE;
}
oop web_curve_to(oop w_, oop c1x_, oop c1y_, oop c2x_, oop c2y_, oop x_, oop y_) {
    GET_WIN(w_); GET_INT(c1x, c1x_); GET_INT(c1y, c1y_); GET_INT(c2x, c2x_); GET_INT(c2y, c2y_);
    GET_INT(x, x_); GET_INT(y, y_);
    w->ctx_curve_to(c1x, c1y, c2x, c2y, x, y); DONE;
}
oop web_close_path(oop w_) { GET_WIN(w_); w->ctx_close_path(); DONE; }
oop web_fill(oop w_)       { GET_WIN(w_); w->ctx_fill(); DONE; }
oop web_stroke(oop w_)     { GET_WIN(w_); w->ctx_stroke(); DONE; }
oop web_arc(oop w_, oop x_, oop y_, oop ww_, oop h_, oop a1_, oop a2_, oop fill_) {
    GET_WIN(w_); GET_INT(x, x_); GET_INT(y, y_); GET_INT(ww, ww_); GET_INT(h, h_);
    GET_INT(a1, a1_); GET_INT(a2, a2_); GET_INT(f, fill_);
    w->ctx_arc(x, y, ww, h, a1, a2, f != 0); DONE;
}
oop web_text_width(oop w_, oop s_) {
    GET_WIN(w_); GET_STR(p, n, s_);
    return self_smi(w->ctx_text_width(p, n));
}

/* ---- pixmaps / images ---------------------------------------------------- */

oop web_create_pixmap(oop w_, oop ww_, oop h_) {
    GET_WIN(w_); GET_INT(ww, ww_); GET_INT(h, h_);
    return self_smi(w->ctx_create_pixmap(ww, h));
}
oop web_free_pixmap(oop w_, oop id_) {
    GET_WIN(w_); GET_INT(id, id_);
    w->ctx_free_pixmap(id); DONE;
}
oop web_set_target(oop w_, oop id_) {
    GET_WIN(w_); GET_INT(id, id_);
    w->ctx_set_target(id); DONE;
}
oop web_copy_area(oop w_, oop src_, oop sx_, oop sy_, oop ww_, oop h_, oop dx_, oop dy_) {
    GET_WIN(w_); GET_INT(src, src_); GET_INT(sx, sx_); GET_INT(sy, sy_);
    GET_INT(ww, ww_); GET_INT(h, h_); GET_INT(dx, dx_); GET_INT(dy, dy_);
    w->ctx_copy_area(src, sx, sy, ww, h, dx, dy); DONE;
}
oop web_define_image(oop w_, oop id_, oop ww_, oop h_, oop idx_, oop pal_, oop transp_) {
    GET_WIN(w_); GET_INT(id, id_); GET_INT(ww, ww_); GET_INT(h, h_); GET_INT(tp, transp_);
    GET_STR(ip, in, idx_); GET_STR(pp, pn, pal_);
    w->ctx_define_image(id, ww, h, ip, in, pp, pn, tp); DONE;
}

/* ---- fonts (global tables; no window handle) ----------------------------- */

oop web_register_font(oop id_, oop fam_, oop bold_, oop ital_) {
    GET_INT(id, id_); GET_STR(fp, fn, fam_); GET_INT(b, bold_); GET_INT(it, ital_);
    wf_register_font(id, fp, fn, b != 0, it != 0); DONE;
}
oop web_font_text_width(oop id_, oop size_, oop s_) {
    GET_INT(id, id_); GET_INT(size, size_); GET_STR(p, n, s_);
    return self_smi(wf_font_text_width(id, size, p, n));
}
oop web_font_ascent(oop id_, oop size_) {
    GET_INT(id, id_); GET_INT(size, size_);
    return self_smi(wf_font_ascent(id, size));
}
oop web_font_descent(oop id_, oop size_) {
    GET_INT(id, id_); GET_INT(size, size_);
    return self_smi(wf_font_descent(id, size));
}
oop web_consume_fonts_relayout(void) {
    bool r = g_fonts_relayout; g_fonts_relayout = false;
    return self_smi(r ? 1 : 0);
}

/* ---- seats / viewers ------------------------------------------------------ */

oop web_set_seat(oop w_, oop s_) {
    GET_WIN(w_); GET_STR(p, n, s_);
    w->set_seat_len(p, n); DONE;
}
oop web_has_viewer(oop w_)  { GET_WIN(w_); return self_smi(w->has_viewer() ? 1 : 0); }
oop web_is_primary(oop w_)  { GET_WIN(w_); return self_smi(w->is_primary() ? 1 : 0); }
oop web_pending_viewers(void) {
    int n = 0;
    for (int i = 0; i < the_server_count; i++)
        if (the_servers[i]) n += the_servers[i]->pending_connection_count();
    return self_smi(n);
}

} // extern "C"
