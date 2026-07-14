/* Copyright 2026 Russell Allen.
   See the LICENSE file for license information. */

// HTML/JS client for the web (browser) Morphic backend.
//
// Served over HTTP GET "/".  Opens a WebSocket to "/ws", receives binary
// command frames ([winId u16][ops...][END_FRAME 0xFF]; SET_TARGET selects the
// drawable), replays them onto per-drawable canvases (windows visible, pixmaps
// offscreen), and sends mouse/keyboard/scroll/resize events back as binary
// messages [winId u16][type u8][payload].  Coords are top-left / y-down,
// matching the canvas.  Keep the opcode/event constants in lock-step with
// webWindow.hh (WBOp / WBEvt).

#ifndef WEB_CLIENT_HH
#define WEB_CLIENT_HH

# if defined(WEB_LIB)

static const char* WEB_CLIENT_HTML = R"CLIENT(<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>Self (web desktop)</title>
<link id="favicon" rel="icon" type="image/svg+xml" href="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 16 16'%3E%3Ccircle cx='8' cy='8' r='7' fill='%234a9d6c'/%3E%3C/svg%3E">
<style>
  html,body { margin:0; padding:0; background:#777; height:100%; font:12px sans-serif; }
  #stage { position:absolute; top:0; left:0; right:0; bottom:0; overflow:auto; }
  canvas { display:block; background:#fff; }
  #status { position:fixed; bottom:3px; right:6px; color:#eee; font:11px monospace; opacity:.6; }
  /* Disconnect banner: fixed at top, pushes the stage down, hidden by default.
     Visible when <body class="disconnected"> -- toggled by the state machine below. */
  #disconBanner { position:fixed; top:0; left:0; right:0; height:28px; line-height:28px;
                  padding:0 12px; background:#b00020; color:#fff; font:13px sans-serif;
                  display:none; z-index:9999; box-sizing:border-box; }
  #disconBanner button { float:right; margin-top:3px; font:12px sans-serif;
                         background:#fff; color:#b00020; border:0; border-radius:3px;
                         padding:2px 10px; cursor:pointer; }
  #disconBanner button[disabled] { opacity:.5; cursor:default; }
  body.disconnected #disconBanner { display:block; }
  body.disconnected #stage { top:28px; }
  body.disconnected canvas { filter: grayscale(1) brightness(0.7); cursor: not-allowed; }
</style>
</head>
<body>
<div id="disconBanner"><span id="disconMsg">⚠ Disconnected from Self</span><button id="disconRetry">Retry now</button></div>
<div id="stage"></div>
<div id="status">connecting…</div>
<script>
"use strict";
const D = {};         // id -> {kind:'win'|'pix', canvas, ctx, w, h}
let active = null;    // active visible window id
let target = null;    // current draw target ctx
let targetD = null;   // current draw target drawable (for per-canvas clip state)
let clipOwner = null; // drawable holding an outstanding clip (one save) across opcodes
let ws = null;
// View zoom + pan, entirely browser-side. The VM always lays the desktop out at the
// full viewport size and renders it into the offscreen buffer pixmap; the browser shows
// a magnified, centred sub-region by giving the visible window context the transform
// (scale Z, translate Tx,Ty) -- canvas2d rasterises under that transform, so it's crisp
// (unlike CSS scaling). The pixmap is allocated at Z x device resolution. Zoom keeps the
// world point under the view centre fixed; the VM stays unaware of zoom (event coords
// are mapped device -> world by (p - T)/Z). Ctrl/Cmd +/-/0 changes the zoom.
let Z = 1, Tx = 0, Ty = 0;
// Per-font advance tables (per-em x1000, ASCII 32..126), keyed by family+style, cached
// when the VM asks us to measure a font. curAdv/curPx track the current SET_FONT so
// DRAW_TEXT can lay glyphs out at the same rounded advances the VM uses for metrics —
// keeping the editor caret aligned with the rendered text. (See measureFont.)
const fontTables = {};
let curAdv = null, curPx = 0;
const fontKey = (fam, bold, ital) => (ital?'i':'') + (bold?'b':'') + (fam || 'sans-serif');
const stage = document.getElementById('stage');
const statusEl = document.getElementById('status');
const banner = document.getElementById('disconBanner');
const bannerMsg = document.getElementById('disconMsg');
const bannerBtn = document.getElementById('disconRetry');
const td = new TextDecoder();
const setStatus = s => statusEl.textContent = s;

// Connection state machine: CONNECTED / DISCONNECTED / RECONNECTING.
//   CONNECTED     -- ws open, normal operation, banner hidden, canvas unfiltered.
//   DISCONNECTED  -- ws closed, waiting out the backoff for the next auto-retry.
//                    Banner shows a live countdown; [Retry now] pre-empts the timer.
//   RECONNECTING  -- a new WebSocket has been issued, onopen has not yet fired.
//                    Banner shows "Reconnecting…" (no countdown), button disabled.
// Input handlers short-circuit when not CONNECTED so a frozen client doesn't queue
// events for a dead server. send() already drops on ws.readyState != 1; this is the
// upstream guard (no encoding cost, no preventDefault ambiguity).
let connState = 'CONNECTED';
// Auto-reconnect: exponential backoff 1, 2, 4, 8, 16, 30, 30… s with up to 250 ms
// jitter on each delay (avoid lockstep reconnect storms across many viewers). No
// give-up; the user can always force-retry with the button.
const BACKOFF_BASE = 1000, BACKOFF_MAX = 30000, BACKOFF_JITTER = 250;
// Stall detection: the server sends a no-op frame every ~5s when otherwise idle, so
// any inbound message proves liveness. If we go STALL_MS without one while still
// CONNECTED, the VM is presumed hung (kill -STOP / deadlock; TCP is still alive so
// onclose never fires) and we trip the disconnect flow ourselves. 12s = 2.4x the
// server period -- tolerates one missed beat + a GC pause.
const STALL_MS = 12000;
let lastFrameAt = Date.now();
let stallTimer = null;
// Set on receiving WB_GOING_AWAY (the server's goodbye); persists through onDisconnect so
// the closing handshake routes to the "Self stopped" state instead of the auto-retry loop.
// Cleared on the next successful onConnect.
let serverGoingAway = false;
let attempt = 0;          // count of failed reconnect tries since last success
let retryTimer = null;    // setTimeout id for the next auto-retry
let countdownTimer = null;// setInterval id for the banner's "in Ns…" tick
let nextRetryAt = 0;      // Date.now() ms when the auto-retry will fire

// Tab-strip indicators: visible even when the tab is backgrounded. The favicon
// swaps to a muted-red variant; the title is prefixed with '⚠ '. The VM owns the
// title via WB_SET_TITLE (opcode 0x84) and may change it any time, so we store the
// VM's most recent unadorned title in baseTitle and rebuild document.title from it
// on every transition. The prefix is stripped before storing so repeated disconnects
// can't stack '⚠ ⚠ ⚠ '. Two SVG data URLs (clean disc, normal teal vs muted red).
const TITLE_PREFIX = '⚠ ';
const FAV_OK  = "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 16 16'%3E%3Ccircle cx='8' cy='8' r='7' fill='%234a9d6c'/%3E%3C/svg%3E";
const FAV_BAD = "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 16 16'%3E%3Ccircle cx='8' cy='8' r='7' fill='%23b00020'/%3E%3C/svg%3E";
const faviconLink = document.getElementById('favicon');
let baseTitle = document.title;
function stripPrefix(s){ return s.startsWith(TITLE_PREFIX) ? s.slice(TITLE_PREFIX.length) : s; }
function setBaseTitle(s){   // called from WB_SET_TITLE and on init
  baseTitle = stripPrefix(s);
  document.title = (connState === 'CONNECTED') ? baseTitle : TITLE_PREFIX + baseTitle;
}

// Reapply a drawable's 2d state after its backing store changed (resizing a canvas
// clears its 2d state). The visible window carries the full view transform (scale Z +
// pan T); offscreen pixmaps are the un-panned Z x render, so they get scale only.
function setDrawableState(d) {
  if (d.kind === 'win') d.ctx.setTransform(Z, 0, 0, Z, Tx, Ty);
  else                  d.ctx.setTransform(Z, 0, 0, Z, 0, 0);
  d.ctx.textBaseline = 'alphabetic';
  d.ctx.font = '13px monospace';
}
function makeCanvas(wDev, hDev, attach) {   // dimensions are DEVICE pixels
  const c = document.createElement('canvas');
  c.width = Math.max(1, Math.round(wDev)); c.height = Math.max(1, Math.round(hDev));
  if (attach) { c.style.display = 'none'; stage.appendChild(c); }
  return { canvas: c, ctx: c.getContext('2d') };
}
function createWindow(id, x, y, w, h, title) {   // the visible window is device-sized (fitActiveToViewport owns it)
  if (D[id]) return;
  const { canvas, ctx } = makeCanvas(w, h, true);
  D[id] = { kind:'win', canvas, ctx, w, h }; setDrawableState(D[id]);
  wireInput(id, canvas);
  setBaseTitle(title || ('Self ' + id));
}
function createPixmap(id, w, h) {   // w,h logical; the pixmap is rendered at Z x device resolution
  if (D[id]) return;
  const { canvas, ctx } = makeCanvas(w * Z, h * Z, false);
  D[id] = { kind:'pix', canvas, ctx, w, h }; setDrawableState(D[id]);
}
function showWindow(id) {
  const d = D[id]; if (!d || d.kind !== 'win') return;
  if (active !== null && D[active]) D[active].canvas.style.display = 'none';
  active = id; d.canvas.style.display = 'block';
  fitActiveToViewport();
}
// The browser is the authority on the window size (like a window manager): size
// the active window's canvas to the viewport and tell the VM, which reflows the
// Self world to match. Resizing the canvas clears it and resets its 2d state, so
// drop our per-canvas clip flag; the resize triggers a full repaint from the VM.
// Pan: when zoomed in (Z>=1) the magnified sub-region must stay inside the desktop. When
// zoomed out (Z<1) the desktop is reflowed to viewport/Z (see fitActiveToViewport) and so
// already fills the viewport at scale Z -- no pan, anchored at the origin.
function clampPan() {
  const vw = Math.max(1, window.innerWidth), vh = Math.max(1, window.innerHeight);
  if (Z >= 1) {
    Tx = Math.min(0, Math.max(vw * (1 - Z), Tx));
    Ty = Math.min(0, Math.max(vh * (1 - Z), Ty));
  } else { Tx = 0; Ty = 0; }
}
function fitActiveToViewport(force) {
  if (active === null) return;
  const d = D[active]; if (!d || d.kind !== 'win') return;
  const vw = Math.max(1, window.innerWidth), vh = Math.max(1, window.innerHeight);
  // The window canvas fills the viewport (device px). The VM's LOGICAL window size: at Z>=1
  // it is the viewport (zoom magnifies a centred sub-region of it); when zoomed out (Z<1)
  // it GROWS to viewport/Z so the desktop reflows to fill the whole viewport at scale Z,
  // instead of shrinking into a centred box with unusable margins.
  const L = (Z < 1) ? Math.max(1, Math.ceil(vw / Z)) : vw;
  const M = (Z < 1) ? Math.max(1, Math.ceil(vh / Z)) : vh;
  if (!force && d.canvas.width === vw && d.canvas.height === vh && d.w === L && d.h === M) return;
  d.canvas.width = vw; d.canvas.height = vh; d.w = L; d.h = M; d.clipped = false;
  clampPan();
  setDrawableState(d);
  const a = []; i16(a, L); i16(a, M); msg(active, 7, a);   // WBE_RESIZE (logical size)
}
function resizeDrawable(id, w, h) {   // w,h logical
  const d = D[id]; if (!d) return;
  // The browser owns the active window's size (fitActiveToViewport); ignore the VM's
  // echo of it, just keep the transform. Pixmaps resize to Z x device resolution.
  if (d.kind === 'win' && id === active) { setDrawableState(d); return; }
  d.w = w; d.h = h; d.canvas.width = Math.max(1,Math.round(w*Z)); d.canvas.height = Math.max(1,Math.round(h*Z));
  setDrawableState(d);
}

function processFrame(dv) {
  const len = dv.byteLength;
  let off = 2;                 // skip the u16 frame window-id
  let ctx = target;
  let curD = targetD;
  // A morphic withClip: block can be split across frames (a flush landing between
  // its SET_CLIP and CLEAR_CLIP), which would otherwise leave the canvas clipped to
  // a damage rect until the next repaint. Never let a clip survive a frame boundary:
  // drop any outstanding clip here; the worst case is the block's tail draws unclipped.
  if (clipOwner && clipOwner.clipped) { clipOwner.ctx.restore(); clipOwner.clipped = false; }
  clipOwner = null;
  while (off < len) {
    const op = dv.getUint8(off++);
    switch (op) {
      case 0x95: { const id = dv.getUint16(off,true); off+=2; const d=D[id]; ctx=d?d.ctx:null; target=ctx; curD=d||null; targetD=curD; break; }
      case 0x06: { const r=dv.getUint8(off),g=dv.getUint8(off+1),b=dv.getUint8(off+2); off+=3; if(ctx){const c='rgb('+r+','+g+','+b+')'; ctx.fillStyle=c; ctx.strokeStyle=c;} break; }
      case 0x07: { const w=dv.getUint16(off,true); off+=2; if(ctx) ctx.lineWidth=w||1; break; }
      case 0x10: { const a=dv.getUint8(off++); if(ctx) ctx.globalAlpha=a/255; break; }
      case 0x0C: { const o=dv.getUint8(off++); if(ctx) ctx.globalCompositeOperation = o===1?'xor':'source-over'; break; }
      case 0x09: { const px=dv.getUint16(off,true); const bold=dv.getUint8(off+2), ital=dv.getUint8(off+3); off+=4; const sl=dv.getUint8(off++); let fam=''; if(sl){fam=td.decode(new Uint8Array(dv.buffer,dv.byteOffset+off,sl)); off+=sl;} if(ctx) ctx.font=(ital?'italic ':'')+(bold?'bold ':'')+px+'px '+(fam||'sans-serif'); curAdv=fontTables[fontKey(fam,bold,ital)]||null; curPx=px; break; }
      // SET_CLIP: morphic clips are ABSOLUTE-REPLACE (it pre-intersects and re-sends
      // the rect to "restore"), not a stack push, so pop any prior clip to baseline
      // before applying the new one — depth never exceeds 1, so it can't leak/shrink.
      case 0x0D: { const x=dv.getInt16(off,true),y=dv.getInt16(off+2,true),w=dv.getUint16(off+4,true),h=dv.getUint16(off+6,true); off+=8; if(ctx){if(curD&&curD.clipped)ctx.restore();ctx.save();ctx.beginPath();ctx.rect(x,y,w,h);ctx.clip();if(curD){curD.clipped=true;clipOwner=curD;}} break; }
      // CLEAR_CLIP: drop back to the unclipped baseline.
      case 0x0E: { if(ctx&&curD&&curD.clipped){ctx.restore();curD.clipped=false;} clipOwner=null; break; }
      case 0x01: { const x=dv.getInt16(off,true),y=dv.getInt16(off+2,true),w=dv.getUint16(off+4,true),h=dv.getUint16(off+6,true); off+=8; if(ctx) ctx.clearRect(x,y,w,h); break; }
      case 0x02: { const x=dv.getInt16(off,true),y=dv.getInt16(off+2,true),w=dv.getUint16(off+4,true),h=dv.getUint16(off+6,true); off+=8; if(ctx) ctx.fillRect(x,y,w,h); break; }
      case 0x03: { const x=dv.getInt16(off,true),y=dv.getInt16(off+2,true),w=dv.getUint16(off+4,true),h=dv.getUint16(off+6,true); off+=8; if(ctx) ctx.strokeRect(x+0.5,y+0.5,w,h); break; }
      case 0x04: { const x1=dv.getInt16(off,true),y1=dv.getInt16(off+2,true),x2=dv.getInt16(off+4,true),y2=dv.getInt16(off+6,true); off+=8; if(ctx){ctx.beginPath();ctx.moveTo(x1+0.5,y1+0.5);ctx.lineTo(x2+0.5,y2+0.5);ctx.stroke();} break; }
      case 0x0F: { const x=dv.getInt16(off,true),y=dv.getInt16(off+2,true); off+=4; if(ctx) ctx.fillRect(x,y,1,1); break; }
      case 0x05: { const x=dv.getInt16(off,true),y=dv.getInt16(off+2,true),n=dv.getUint16(off+4,true); off+=6; const s=td.decode(new Uint8Array(dv.buffer,dv.byteOffset+off,n)); off+=n;
        if(ctx){ if(curAdv){ // lay each glyph out at the same rounded advance the VM measures
            let gx=x; const dn=curAdv['n'.charCodeAt(0)-32];
            for(let i=0;i<s.length;i++){ ctx.fillText(s[i],gx,y); const cc=s.charCodeAt(i); const a=(cc>=32&&cc<=126)?curAdv[cc-32]:dn; gx += Math.round(a*curPx/1000); }
          } else ctx.fillText(s,x,y); } break; }
      case 0x11: { if(ctx) ctx.beginPath(); break; }
      case 0x12: { const x=dv.getInt16(off,true),y=dv.getInt16(off+2,true); off+=4; if(ctx) ctx.moveTo(x,y); break; }
      case 0x13: { const x=dv.getInt16(off,true),y=dv.getInt16(off+2,true); off+=4; if(ctx) ctx.lineTo(x,y); break; }
      case 0x14: { const a=dv.getInt16(off,true),b=dv.getInt16(off+2,true),c=dv.getInt16(off+4,true),d=dv.getInt16(off+6,true),e=dv.getInt16(off+8,true),f=dv.getInt16(off+10,true); off+=12; if(ctx) ctx.bezierCurveTo(a,b,c,d,e,f); break; }
      case 0x16: { if(ctx) ctx.closePath(); break; }
      case 0x17: { if(ctx) ctx.fill(); break; }
      case 0x18: { if(ctx) ctx.stroke(); break; }
      case 0x15: { const x=dv.getInt16(off,true),y=dv.getInt16(off+2,true),w=dv.getUint16(off+4,true),h=dv.getUint16(off+6,true),a1=dv.getInt16(off+8,true),a2=dv.getInt16(off+10,true),fill=dv.getUint8(off+12); off+=13; if(ctx) drawArc(ctx,x,y,w,h,a1,a2,fill); break; }
      case 0x1A: case 0x1B: { const n=dv.getUint16(off,true); off+=2; if(ctx) ctx.beginPath(); for(let i=0;i<n;i++){const px=dv.getInt16(off,true),py=dv.getInt16(off+2,true); off+=4; if(ctx){i===0?ctx.moveTo(px+0.5,py+0.5):ctx.lineTo(px+0.5,py+0.5);}} if(ctx){ if(op===0x1B){ctx.closePath();ctx.fill();} else ctx.stroke(); } break; }
      case 0x92: { const sid=dv.getUint16(off,true),sx=dv.getInt16(off+2,true),sy=dv.getInt16(off+4,true),w=dv.getUint16(off+6,true),h=dv.getUint16(off+8,true),dx=dv.getInt16(off+10,true),dy=dv.getInt16(off+12,true); off+=14; const src=D[sid]; if(ctx&&src&&w>0&&h>0) ctx.drawImage(src.canvas, sx*Z,sy*Z,w*Z,h*Z, dx,dy,w,h); break; }
      case 0x80: { const id=dv.getUint16(off,true),x=dv.getInt16(off+2,true),y=dv.getInt16(off+4,true),w=dv.getUint16(off+6,true),h=dv.getUint16(off+8,true),tl=dv.getUint8(off+10); off+=11; let s=''; if(tl){s=td.decode(new Uint8Array(dv.buffer,dv.byteOffset+off,tl)); off+=tl;} createWindow(id,x,y,w,h,s); break; }
      case 0x81: { const id=dv.getUint16(off,true); off+=2; const d=D[id]; if(d){if(d.canvas.parentNode)d.canvas.remove(); delete D[id];} break; }
      case 0x82: { const id=dv.getUint16(off,true),w=dv.getUint16(off+2,true),h=dv.getUint16(off+4,true); off+=6; resizeDrawable(id,w,h); break; }
      case 0x83: { off+=6; break; }
      case 0x84: { const id=dv.getUint16(off,true),tl=dv.getUint8(off+2); off+=3; const s=td.decode(new Uint8Array(dv.buffer,dv.byteOffset+off,tl)); off+=tl; if(+id===active) setBaseTitle(s); break; }
      case 0x85: { const id=dv.getUint16(off,true); off+=2; showWindow(id); break; }
      case 0x86: { const id=dv.getUint16(off,true); off+=2; const d=D[id]; if(d)d.canvas.style.display='none'; break; }
      case 0x90: { const id=dv.getUint16(off,true),w=dv.getUint16(off+2,true),h=dv.getUint16(off+4,true); off+=6; createPixmap(id,w,h); break; }
      case 0x91: { const id=dv.getUint16(off,true); off+=2; delete D[id]; break; }
      case 0x93: { // WB_SET_CLIPBOARD: len u16 + utf8 -> write the viewer's OS clipboard
        const n=dv.getUint16(off,true); off+=2;
        const t=td.decode(new Uint8Array(dv.buffer,dv.byteOffset+off,n)); off+=n;
        if (navigator.clipboard && navigator.clipboard.writeText) navigator.clipboard.writeText(t).catch(()=>{});
        break; }
      case 0x61: { // WB_DEFINE_IMAGE: id u16, w u16, h u16, rgba (w*h*4) -> fill pixmap id
        const id=dv.getUint16(off,true),w=dv.getUint16(off+2,true),h=dv.getUint16(off+4,true); off+=6;
        const n=w*h*4, d=D[id];
        if (d && w>0 && h>0) {
          const px=new Uint8ClampedArray(dv.buffer.slice(dv.byteOffset+off, dv.byteOffset+off+n));
          // keep the native-resolution source so it can be re-blitted when zoom resizes the canvas
          const tmp=document.createElement('canvas'); tmp.width=w; tmp.height=h;
          tmp.getContext('2d').putImageData(new ImageData(px,w,h),0,0);
          d.srcImg=tmp; d.ctx.drawImage(tmp,0,0,w,h);   // d.ctx has the Z transform -> scales to w*Z
        }
        off+=n; break;
      }
      case 0x62: { // WB_MEASURE_FONT: id u16, bold u8, italic u8, famLen u8, family
        const fid=dv.getUint16(off,true), bold=dv.getUint8(off+2), ital=dv.getUint8(off+3), fl=dv.getUint8(off+4); off+=5;
        let fam=''; if(fl){ fam=td.decode(new Uint8Array(dv.buffer,dv.byteOffset+off,fl)); off+=fl; }
        measureFont(fid, fam, bold, ital); break; }
      case 0xFE: serverGoingAway = true; break;   // WB_GOING_AWAY: VM is shutting down; onDisconnect will route to VM_STOPPED
      case 0xFF: return;
      default: console.error('unknown opcode 0x'+op.toString(16)+' @'+(off-1)); return;
    }
  }
}
// Measure a (family,style) with canvas measureText and send the VM a per-character
// advance table (ASCII 32..126) + ascent/descent, all per-em x1000 at a base size, as
// a WBE_FONT_TABLE message (type 12). Lets the VM compute exact proportional widths.
function measureFont(fid, fam, bold, ital){
  if (!(ws && ws.readyState === 1)) return;
  const B = 256, c = document.createElement('canvas').getContext('2d');
  c.font = (ital?'italic ':'') + (bold?'bold ':'') + B + 'px ' + (fam || 'sans-serif');
  const milli = x => Math.max(0, Math.min(65535, Math.round(x * 1000)));
  const tbl = [];
  for (let ch=32; ch<=126; ch++) tbl.push(milli(c.measureText(String.fromCharCode(ch)).width / B));
  fontTables[fontKey(fam, bold, ital)] = tbl;   // cache for per-glyph layout in DRAW_TEXT
  const a = []; i16(a, fid);
  for (let i=0; i<tbl.length; i++) i16(a, tbl[i]);
  const m = c.measureText('Mg'); let asc=m.fontBoundingBoxAscent, desc=m.fontBoundingBoxDescent;
  if (!(asc > 0)) { asc = 0.8*B; desc = 0.2*B; }
  i16(a, milli(asc / B)); i16(a, milli(desc / B));
  msg(active === null ? 1 : active, 12, a);   // WBE_FONT_TABLE
}

function drawArc(ctx,x,y,w,h,a1,a2,fill){
  const cx=x+w/2, cy=y+h/2, rx=Math.abs(w/2), ry=Math.abs(h/2);
  const s=-(a1/64)*Math.PI/180, e=-((a1+a2)/64)*Math.PI/180;
  ctx.beginPath();
  if (ctx.ellipse) ctx.ellipse(cx,cy,rx,ry,0,s,e,a2>0); else ctx.arc(cx,cy,rx,s,e,a2>0);
  if (fill) ctx.fill(); else ctx.stroke();
}

// --- input ---
function modBits(ev){ let m=0; if(ev.shiftKey)m|=1; if(ev.ctrlKey||ev.metaKey)m|=2; if(ev.altKey)m|=4; return m; }
// Map a browser mouse event to [xButton(1=left,2=middle,3=right), mods].
// Only a plain left click is the left button. Every secondary-click gesture maps
// to the middle "blue" button (which opens the menu), so they all behave alike:
// Control+click (DOM button 0 + ctrlKey), a two-finger trackpad click (DOM button
// 1 or 2 depending on the device), and a real right button (DOM button 2). The
// Control modifier bit is stripped so Self sees a plain middle click.
function xButtonMods(ev){
  let mods = modBits(ev);
  if (ev.button === 0 && !ev.ctrlKey) return [1, mods];
  return [2, mods & ~2];
}
function canvasXY(d,ev){ const r=d.canvas.getBoundingClientRect(); const sx=d.canvas.width/r.width, sy=d.canvas.height/r.height; const dx=(ev.clientX-r.left)*sx, dy=(ev.clientY-r.top)*sy; return [Math.round((dx-Tx)/Z), Math.round((dy-Ty)/Z)]; }
function send(buf){ if(ws&&ws.readyState===1) ws.send(buf); }
function msg(winId,type,bytes){ const b=new Uint8Array(3+bytes.length); const dv=new DataView(b.buffer); dv.setUint16(0,winId,true); dv.setUint8(2,type); b.set(bytes,3); send(b.buffer); }
function i16(a,v){ a.push(v&0xff,(v>>8)&0xff); }
function u32(a,v){ a.push(v&0xff,(v>>8)&0xff,(v>>16)&0xff,(v>>>24)&0xff); }

function keysymFor(ev){
  const k=ev.key;
  if(k.length===1) return k.charCodeAt(0);
  switch(k){
    case 'Enter': return 0xff0d; case 'Backspace': return 0xff08; case 'Tab': return 0xff09;
    case 'Escape': return 0xff1b; case 'Delete': return 0xffff;
    case 'ArrowLeft': return 0xff51; case 'ArrowUp': return 0xff52;
    case 'ArrowRight': return 0xff53; case 'ArrowDown': return 0xff54;
    case 'Home': return 0xff50; case 'End': return 0xff57;
    case 'PageUp': return 0xff55; case 'PageDown': return 0xff56;
    default: return 0;
  }
}
// The character the VM sees (event keystrokes). The editor maps editing keys by their
// control CHARACTER (8=backspace, 9=tab, 13=enter, 27=escape, 127=delete -- see
// ui2Event keyCapForCharacter:), so multi-char keys must report that char, not 0.
function charFor(ev){
  if (ev.key.length === 1) return ev.key.charCodeAt(0);
  switch(ev.key){
    case 'Backspace': return 8;  case 'Tab': return 9;   case 'Enter': return 13;
    case 'Escape':    return 27; case 'Delete': return 127;
    default: return 0;   // arrows etc. are handled via the keysym, not a character
  }
}

function wireInput(id, canvas){
  const d = D[id];
  canvas.addEventListener('mousedown', ev=>{ if(connState!=='CONNECTED')return; ev.preventDefault(); const [x,y]=canvasXY(d,ev); const [btn,mods]=xButtonMods(ev); const a=[]; i16(a,x); i16(a,y); a.push(btn, mods); msg(id,1,a); });
  canvas.addEventListener('mouseup',   ev=>{ if(connState!=='CONNECTED')return; ev.preventDefault(); const [x,y]=canvasXY(d,ev); const [btn,mods]=xButtonMods(ev); const a=[]; i16(a,x); i16(a,y); a.push(btn, mods); msg(id,2,a); });
  canvas.addEventListener('mousemove', ev=>{ if(connState!=='CONNECTED')return; const [x,y]=canvasXY(d,ev); const a=[]; i16(a,x); i16(a,y); a.push(modBits(ev)); msg(id,3,a); });
  canvas.addEventListener('contextmenu', ev=>ev.preventDefault());
  canvas.addEventListener('wheel', ev=>{ if(connState!=='CONNECTED')return; ev.preventDefault(); const [x,y]=canvasXY(d,ev); const a=[]; i16(a,x); i16(a,y); i16(a, ev.deltaY<0?-1:1); a.push(modBits(ev)); msg(id,6,a); });
}
// Change the view zoom: the new logical window size (viewport/Z) is pushed to the VM,
// which reflows and recreates the buffer pixmap at the new scale; a full redraw repaints.
function setZoom(z){
  z = Math.max(0.25, Math.min(4, z));
  if (Math.abs(z - Z) < 1e-6) return;
  const cx = Math.max(1, window.innerWidth) / 2, cy = Math.max(1, window.innerHeight) / 2;
  // keep the world point under the view centre fixed:  T' = c - (c - T) * (z/Z)
  Tx = cx - (cx - Tx) * (z / Z);
  Ty = cy - (cy - Ty) * (z / Z);
  Z = z;
  // resize the VM's logical window for the new zoom (zoom-out grows it to fill the viewport,
  // zoom-in keeps it at the viewport) and reapply the window transform/pan.
  fitActiveToViewport(true);
  // reallocate offscreen pixmaps for the new device scale (Z>=1 keeps the logical size, so
  // the VM doesn't recreate its buffer; Z<1 reflows and the VM recreates it).
  for (const k in D) { const d = D[k];
    if (d.kind !== 'win') { d.canvas.width = Math.max(1,Math.round(d.w*Z)); d.canvas.height = Math.max(1,Math.round(d.h*Z)); setDrawableState(d);
      if (d.srcImg) d.ctx.drawImage(d.srcImg, 0, 0, d.w, d.h); }   // image pixmaps: re-blit (resize cleared the canvas)
  }
  const w = active!==null && D[active]; if (w) { w.ctx.save(); w.ctx.setTransform(1,0,0,1,0,0); w.ctx.clearRect(0,0,w.canvas.width,w.canvas.height); w.ctx.restore(); }
  requestRedraw();
  setStatus('connected · ' + Math.round(Z*100) + '%');
}
window.addEventListener('keydown', ev=>{
  // Ctrl/Cmd +/-/0 zoom the view (intercepted before the browser's own page zoom).
  if ((ev.ctrlKey||ev.metaKey) && !ev.altKey && (ev.key==='='||ev.key==='+'||ev.key==='-'||ev.key==='_'||ev.key==='0')) {
    ev.preventDefault();
    if (ev.key==='0') setZoom(1); else setZoom((ev.key==='-'||ev.key==='_') ? Z/1.25 : Z*1.25);
    return;
  }
  // Ctrl/Cmd + arrows pan the view across the whole Morphic world by ~20% of what's
  // visible. Pan is a VM operation (it moves the world-canvas offset, so morphs outside
  // the old view are drawn as they scroll in) -- the browser only sends the world-unit
  // delta; it cannot reveal morphs the VM never painted. Works at every zoom level.
  if ((ev.ctrlKey||ev.metaKey) && !ev.altKey &&
      (ev.key==='ArrowLeft'||ev.key==='ArrowRight'||ev.key==='ArrowUp'||ev.key==='ArrowDown')) {
    ev.preventDefault();
    // a world unit draws as Z device px, so the visible world spans viewport/Z; step 20%.
    const sx = Math.round(0.2 * Math.max(1, window.innerWidth)  / Z);
    const sy = Math.round(0.2 * Math.max(1, window.innerHeight) / Z);
    let dx = 0, dy = 0;
    if      (ev.key==='ArrowRight') dx =  sx;
    else if (ev.key==='ArrowLeft')  dx = -sx;
    else if (ev.key==='ArrowDown')  dy =  sy;
    else                            dy = -sy;
    const a = []; i16(a, dx); i16(a, dy); msg(active, 11, a);   // WBE_PAN (world units)
    return;
  }
  // Cmd/Ctrl+V: let the browser 'paste' event deliver the OS clipboard (injected as input
  // below); don't also send it as a keystroke (which the editor would treat as something else).
  if ((ev.ctrlKey||ev.metaKey) && !ev.altKey && (ev.key==='v'||ev.key==='V')) return;
  // Network-bound from here down -- zoom (above) and pan (above) keep working offline as
  // local-only transforms; keystrokes need a live VM, so drop them while disconnected.
  if (connState !== 'CONNECTED') return;
  if(active===null)return; const ks=keysymFor(ev); if(!ks)return; if(ev.ctrlKey||ev.metaKey||ev.altKey||ev.key.length>1) ev.preventDefault(); const ch=charFor(ev); const a=[]; u32(a,ks); u32(a,ch); a.push(modBits(ev)); msg(active,4,a); });
window.addEventListener('keyup',   ev=>{ if(connState!=='CONNECTED')return; if(active===null)return; const ks=keysymFor(ev); if(!ks)return; const ch=charFor(ev); const a=[]; u32(a,ks); u32(a,ch); a.push(modBits(ev)); msg(active,5,a); });
window.addEventListener('resize', ()=>fitActiveToViewport(false));
// Inject text into Self as keystrokes (used to paste the OS clipboard, which the editor's
// emacs-style yank cannot pull from the browser directly).
function typeText(s){
  if (active === null) return;
  for (const ch of s) {
    const cp = ch.codePointAt(0);
    let keysym, code;
    if      (ch === '\n' || ch === '\r') { keysym = 0xff0d; code = 13; }
    else if (ch === '\t')                { keysym = 0xff09; code = 9;  }
    else if (cp < 32)                    { continue; }   // skip other control chars
    else                                 { keysym = cp;    code = cp; }
    let a=[]; u32(a,keysym); u32(a,code); a.push(0); msg(active,4,a);   // keydown
    a=[];     u32(a,keysym); u32(a,code); a.push(0); msg(active,5,a);   // keyup
  }
}
// Paste (Cmd/Ctrl+V): deliver the viewer's OS clipboard into Self as typed input.
document.addEventListener('paste', ev=>{
  if (connState !== 'CONNECTED') return;
  ev.preventDefault();
  const t = (ev.clipboardData || window.clipboardData).getData('text/plain');
  if (t) typeText(t);
});

// This page's seat = its URL path ("/" -> "", "/alice" -> "alice"). Each distinct seat
// is a distinct hand on the shared desktop; declared to the server on the WebSocket.
const seat = location.pathname.replace(/^\/+|\/+$/g, '');
function connect(){
  ws = new WebSocket('ws://'+location.host+'/ws'+(seat ? ('?seat='+encodeURIComponent(seat)) : ''));
  ws.binaryType='arraybuffer';
  ws.onopen    = onConnect;
  ws.onclose   = onDisconnect;
  ws.onmessage = ev => { lastFrameAt = Date.now(); try { processFrame(new DataView(ev.data)); } catch(e){ console.error(e); } };
}
// onopen: clear all reconnect state and visuals; request a full repaint so the
// server's replay_window_to + a fresh redraw bring the canvas back in sync.
function onConnect(){
  connState = 'CONNECTED';
  attempt = 0;
  serverGoingAway = false;   // a fresh successful connect supersedes any prior goodbye
  clearTimeout(retryTimer); retryTimer = null;
  clearInterval(countdownTimer); countdownTimer = null;
  document.body.classList.remove('disconnected');
  bannerBtn.disabled = false;
  faviconLink.href = FAV_OK;
  document.title = baseTitle;
  setStatus('connected');
  // arm the stall watchdog: any inbound frame (incl. the server's no-op heartbeat)
  // resets lastFrameAt; if STALL_MS passes without one, declareStall trips disconnect.
  lastFrameAt = Date.now();
  clearInterval(stallTimer);
  stallTimer = setInterval(checkStall, 1000);
  // Tell the server our actual viewport size BEFORE it starts pumping the initial / replay
  // frames. Otherwise the server paints at its stored logical size (preferences desktop
  // initialBounds on first boot, or the last resize on reconnect) and the browser sees one
  // or two paint cycles at the wrong size before showWindow's fitActiveToViewport corrects
  // it. The size goes out as a logical-size WBE_RESIZE (viewport/Z when zoomed out, viewport
  // otherwise) to match what fitActiveToViewport emits later, so the two sites agree.
  { const vw = Math.max(1, window.innerWidth), vh = Math.max(1, window.innerHeight);
    const L = (Z < 1) ? Math.max(1, Math.ceil(vw / Z)) : vw;
    const M = (Z < 1) ? Math.max(1, Math.ceil(vh / Z)) : vh;
    const a = []; i16(a, L); i16(a, M);
    msg(active === null ? 1 : active, 7, a); }   // WBE_RESIZE
  requestRedraw();
}
function checkStall(){
  if (connState !== 'CONNECTED') return;
  if (Date.now() - lastFrameAt > STALL_MS) declareStall();
}
function declareStall(){
  // Synthesise the disconnect ourselves: the TCP socket is alive but the server is
  // unresponsive (VM suspended/deadlocked), so onclose would never fire on its own.
  // Detach handlers + close to suppress the eventual zombie onclose; reset attempt
  // through onDisconnect's normal C->D path -> first retry at the BACKOFF_BASE delay.
  try { ws.onopen = null; ws.onclose = null; ws.onmessage = null; ws.close(); } catch(e){}
  onDisconnect();
}
// onclose: enter DISCONNECTED, show the banner, grey + lock the canvas, and
// schedule the next auto-retry. Counts as a failed `attempt` only if we were
// already in RECONNECTING (i.e. the just-issued ws didn't make it to onopen);
// the first close from CONNECTED keeps attempt at 0 -> first delay = BASE = 1s.
function onDisconnect(){
  if (connState === 'RECONNECTING') attempt += 1;
  document.body.classList.add('disconnected');
  bannerBtn.disabled = false;
  faviconLink.href = FAV_BAD;
  document.title = TITLE_PREFIX + baseTitle;
  if (serverGoingAway) {
    // VM signalled a clean shutdown -- no auto-retry; user clicks Retry when they've
    // restarted Self. The flag stays set across failed manual retries (each failure
    // re-enters this branch) and is only cleared by a successful onConnect.
    connState = 'VM_STOPPED';
    clearTimeout(retryTimer); retryTimer = null;
    clearInterval(countdownTimer); countdownTimer = null;
    bannerMsg.textContent = '⚠ Self stopped — restart Self and click Retry';
  } else {
    connState = 'DISCONNECTED';
    scheduleReconnect();
  }
}
function scheduleReconnect(){
  clearTimeout(retryTimer);
  const delay = Math.min(BACKOFF_MAX, BACKOFF_BASE * Math.pow(2, attempt))
              + Math.random() * BACKOFF_JITTER;
  nextRetryAt = Date.now() + delay;
  retryTimer = setTimeout(doReconnect, delay);
  renderCountdown();   // first paint, then 4Hz updates
  clearInterval(countdownTimer);
  countdownTimer = setInterval(renderCountdown, 250);
}
function renderCountdown(){
  const secs = Math.max(0, Math.ceil((nextRetryAt - Date.now()) / 1000));
  bannerMsg.textContent = '⚠ Disconnected from Self — reconnecting in ' + secs + 's…';
}
// Fire the new WebSocket attempt; transition to RECONNECTING and freeze the banner.
function doReconnect(){
  clearTimeout(retryTimer); retryTimer = null;
  clearInterval(countdownTimer); countdownTimer = null;
  connState = 'RECONNECTING';
  bannerMsg.textContent = '⚠ Reconnecting…';
  bannerBtn.disabled = true;
  connect();
}
// [Retry now] pre-empts the auto-retry timer and fires an immediate attempt.
bannerBtn.addEventListener('click', function(){
  if (connState === 'RECONNECTING') return;
  doReconnect();
});
// Ask the server for a full redraw (type 10) — used to resync after a reconnect or when
// a backgrounded tab becomes visible again (it may have missed throttled frames).
function requestRedraw(){ if (ws && ws.readyState === 1) msg(active === null ? 1 : active, 10, []); }
document.addEventListener('visibilitychange', function(){
  if (document.visibilityState === 'visible') requestRedraw();
});
connect();
// App-level heartbeat: a tiny message every ~10s. The server bumps the connection's
// last-seen on any inbound frame and reaps connections silent past the timeout, so a
// half-open socket (Wi-Fi drop, sleep) is dropped promptly instead of lingering. Type 9
// carries no event payload (the server's on_ws_data ignores it).
setInterval(function(){ if (ws && ws.readyState === 1) msg(active === null ? 1 : active, 9, []); }, 10000);
</script>
</body>
</html>
)CLIENT";

# endif // WEB_LIB
#endif // WEB_CLIENT_HH
