 "webPlugin.self -- Self-side binding for the web (browser) backend plugin.

  The backend lives in an oop-library (this repo -> libweb.dylib/.so):
  an embedded civetweb HTTP+WebSocket server that ships a binary opcode
  stream to an HTML5-canvas client and queues browser input.  This file is
  the hand-written replacement for the generated glue wrappers the in-VM
  backend used (objects/glue/web_wrappers.self on the web-backend branch):

   - webGlobals webLib dlopens the library, runs the _InitSelfLibrary
     handshake, and looks up every exported function into a fctProxy with
     its arity declared (_NoOfArgs:), so wrong-arity calls fail cleanly.

   - traits web platformWindow gets the same raw wrapper selectors the
     generated glue installed (fillRectX:Y:Width:Height:, eventsPending,
     registerFont:Family:Bold:Italic:, ...), each forwarding through the
     corresponding fctProxy.  Windows are identified by the handle slot
     winId (see web.self); the font/viewer functions are global and
     ignore the receiver, so they still work on the dead prototype.

  Booleans cross the ABI as 0/1 smis (ABI 1.0 has no boolean helpers); the
  wrappers convert in both directions.  Strings/byte data cross as
  byteVectors.  The clipboard read is the one string RETURN: the library
  cannot allocate, so getScrap asks for the length, makes a mutableString,
  and has the library fill it.

  Proxies die when a snapshot is written and re-read; openDisplay:...
  re-runs webLib ensureLoaded, and the web world discipline of opening the
  desktop fresh on resume (desktop openWebFromEnv as a scheduler-initial
  message) means no window handle outlives its process.

  File in after web.self (needs traits web platformWindow and the winId
  handle slot) and webHosts.self (needs webGlobals)."


 '-- webGlobals webLib: the library handle + one fctProxy per export'

 webGlobals _AddSlots: ( |
    webLib = ( |
        parent* = traits clonable.

        "the dlopened library (a proxy); nil until load"
        so.

        "window lifecycle"
        open. close. isOpen. left. top. width. height. setExtent.
        "events (pop-then-read) + view pan"
        eventsPending. nextEventType.
        eventX. eventY. eventButton. eventState. eventKeysym. eventChar.
        eventW. eventH.
        takePanX. takePanY.
        "clipboard"
        scrapLength. scrapInto. putScrap.
        "drawing context"
        beginDraw. endDraw.
        setColor. setLineWidth. setFont. setAlpha. setClip. clearClip.
        fillRect. strokeRect. clearRect. drawLine. drawText. drawPoint.
        beginPath. moveTo. lineTo. curveTo. closePath. fill. stroke. arc.
        textWidth.
        "pixmaps / images"
        createPixmap. freePixmap. setTarget. copyArea. defineImage.
        "fonts (global tables)"
        registerFont. fontTextWidth. fontAscent. fontDescent.
        consumeFontsRelayout.
        "seats / viewers"
        setSeat. hasViewer. isPrimary. pendingViewers.

        "Loaded and still live?  fctProxies and the library proxy die when a
         snapshot is re-read; ensureLoaded then reloads (re-init is idempotent)."
        isLoaded = ( so isNotNil && [so isLive] ).

        ensureLoaded = ( isLoaded ifFalse: [ load ]. self ).

        "Look up an export and declare its true arity, so the _Call arity
         guard is live (a wrong-arity call fails instead of reading garbage)."
        fct: aName Arity: n = ( | f |
            f: fctProxy clone.
            so _FctLookup: aName ResultProxy: f
               IfFail: [|:e| ^ error: 'webPlugin: no ', aName, ': ', e].
            f _NoOfArgs: n.
            f).

        "directories searched for the library, each a repo root whose plugin/
         holds libweb: $SELF_WEB_PLUGIN_DIR first, then this repo as a sibling
         of the VM's working directory (the usual launch-from-self64-root
         layout), then the working directory itself"
        libDirs = ( | dirs. d |
            dirs: list copyRemoveAll.
            d: os environmentAt: 'SELF_WEB_PLUGIN_DIR' IfFail: nil.
            d ifNotNil: [ dirs add: d, '/plugin' ].
            dirs add: '../self-browser-backend/plugin'.
            dirs add: 'plugin'.
            dirs ).

        "dlopen dir/libweb.dylib or dir/libweb.so; nil if neither is there"
        tryOpen: dir = ( | p |
            p: proxy clone.
            (dir, '/libweb.dylib') _Dlopen: 1 ResultProxy: p IfFail: [|:e|
                p: proxy clone.
                (dir, '/libweb.so') _Dlopen: 1 ResultProxy: p IfFail: [|:e2| ^ nil]].
            p ).

        "dlopen the library, run the handshake, and bind every export."
        load = ( | p |
            libDirs do: [|:d| p isNil ifTrue: [ p: tryOpen: d ]].
            p isNil ifTrue: [
                ^ error: 'webPlugin: cannot dlopen libweb.dylib|.so ',
                         '(build it with make in self-browser-backend/plugin, ',
                         'or set SELF_WEB_PLUGIN_DIR to the repo root)'].
            p _InitSelfLibraryIfFail: [|:e| ^ error: 'webPlugin: init: ', e].
            so: p.

            open:            fct: 'web_open'            Arity: 7.
            close:           fct: 'web_close'           Arity: 1.
            isOpen:          fct: 'web_is_open'         Arity: 1.
            left:            fct: 'web_left'            Arity: 1.
            top:             fct: 'web_top'             Arity: 1.
            width:           fct: 'web_width'           Arity: 1.
            height:          fct: 'web_height'          Arity: 1.
            setExtent:       fct: 'web_set_extent'      Arity: 5.

            eventsPending:   fct: 'web_events_pending'  Arity: 1.
            nextEventType:   fct: 'web_next_event_type' Arity: 1.
            eventX:          fct: 'web_event_x'         Arity: 1.
            eventY:          fct: 'web_event_y'         Arity: 1.
            eventButton:     fct: 'web_event_button'    Arity: 1.
            eventState:      fct: 'web_event_state'     Arity: 1.
            eventKeysym:     fct: 'web_event_keysym'    Arity: 1.
            eventChar:       fct: 'web_event_char'      Arity: 1.
            eventW:          fct: 'web_event_w'         Arity: 1.
            eventH:          fct: 'web_event_h'         Arity: 1.
            takePanX:        fct: 'web_take_pan_x'      Arity: 1.
            takePanY:        fct: 'web_take_pan_y'      Arity: 1.

            scrapLength:     fct: 'web_scrap_length'    Arity: 1.
            scrapInto:       fct: 'web_scrap_into'      Arity: 2.
            putScrap:        fct: 'web_put_scrap'       Arity: 2.

            beginDraw:       fct: 'web_begin_draw'      Arity: 1.
            endDraw:         fct: 'web_end_draw'        Arity: 1.
            setColor:        fct: 'web_set_color'       Arity: 4.
            setLineWidth:    fct: 'web_set_line_width'  Arity: 2.
            setFont:         fct: 'web_set_font'        Arity: 5.
            setAlpha:        fct: 'web_set_alpha'       Arity: 2.
            setClip:         fct: 'web_set_clip'        Arity: 5.
            clearClip:       fct: 'web_clear_clip'      Arity: 1.
            fillRect:        fct: 'web_fill_rect'       Arity: 5.
            strokeRect:      fct: 'web_stroke_rect'     Arity: 5.
            clearRect:       fct: 'web_clear_rect'      Arity: 5.
            drawLine:        fct: 'web_draw_line'       Arity: 5.
            drawText:        fct: 'web_draw_text'       Arity: 4.
            drawPoint:       fct: 'web_draw_point'      Arity: 3.
            beginPath:       fct: 'web_begin_path'      Arity: 1.
            moveTo:          fct: 'web_move_to'         Arity: 3.
            lineTo:          fct: 'web_line_to'         Arity: 3.
            curveTo:         fct: 'web_curve_to'        Arity: 7.
            closePath:       fct: 'web_close_path'      Arity: 1.
            fill:            fct: 'web_fill'            Arity: 1.
            stroke:          fct: 'web_stroke'          Arity: 1.
            arc:             fct: 'web_arc'             Arity: 8.
            textWidth:       fct: 'web_text_width'      Arity: 2.

            createPixmap:    fct: 'web_create_pixmap'   Arity: 3.
            freePixmap:      fct: 'web_free_pixmap'     Arity: 2.
            setTarget:       fct: 'web_set_target'      Arity: 2.
            copyArea:        fct: 'web_copy_area'       Arity: 8.
            defineImage:     fct: 'web_define_image'    Arity: 7.

            registerFont:    fct: 'web_register_font'   Arity: 4.
            fontTextWidth:   fct: 'web_font_text_width' Arity: 3.
            fontAscent:      fct: 'web_font_ascent'     Arity: 2.
            fontDescent:     fct: 'web_font_descent'    Arity: 2.
            consumeFontsRelayout: fct: 'web_consume_fonts_relayout' Arity: 0.

            setSeat:         fct: 'web_set_seat'        Arity: 2.
            hasViewer:       fct: 'web_has_viewer'      Arity: 1.
            isPrimary:       fct: 'web_is_primary'      Arity: 1.
            pendingViewers:  fct: 'web_pending_viewers' Arity: 0.

            self).
    | ).
 | ).


 '-- the raw wrappers on traits web platformWindow (the selectors the
    generated glue used to install; graphics/web.self and ui2/webCanvas.self
    build the morphic drawable/gc/canvas protocols on top of these)'

 traits web platformWindow _AddSlots: ( |
    "the plugin binding"
    lib = ( webGlobals webLib ).

    "----- window lifecycle -----"

    "a fresh handle; the C++ window is created by openDisplay:..."
    new = ( deadCopy ).

    "min/max size, icon name and font name are accepted for platformWindow
     interface compatibility but ignored, exactly as the in-VM backend
     ignored them."
    openDisplay: dn Left: l Top: t Width: w Height: h
        MinWidth: mnw MaxWidth: mxw MinHeight: mnh MaxHeight: mxh
        WindowName: wn IconName: icn FontName: fn FontSize: fs = (
        lib ensureLoaded.
        winId: lib open _Call: dn With: l With: t With: w With: h With: wn With: fs.
        1).

    basicClose = ( lib close _Call: winId. self ).
    raw_isOpen = ( 1 = (lib isOpen _Call: winId) ).
    left       = ( lib left   _Call: winId ).
    top        = ( lib top    _Call: winId ).
    width      = ( lib width  _Call: winId ).
    height     = ( lib height _Call: winId ).
    setLeft: l Top: t Width: w Height: h = (
        lib setExtent _Call: winId With: l With: t With: w With: h. self ).

    "----- events: nextEventType pops into the current event, the eventX...
     accessors read its fields (webEvents.self drives this) -----"

    eventsPending = ( lib eventsPending _Call: winId ).
    nextEventType = ( lib nextEventType _Call: winId ).
    eventX      = ( lib eventX      _Call: winId ).
    eventY      = ( lib eventY      _Call: winId ).
    eventButton = ( lib eventButton _Call: winId ).
    eventState  = ( lib eventState  _Call: winId ).
    eventKeysym = ( lib eventKeysym _Call: winId ).
    eventChar   = ( lib eventChar   _Call: winId ).
    eventW      = ( lib eventW      _Call: winId ).
    eventH      = ( lib eventH      _Call: winId ).
    takePanX    = ( lib takePanX    _Call: winId ).
    takePanY    = ( lib takePanY    _Call: winId ).

    "----- clipboard -----"

    getScrap = ( | n. buf |
        n: lib scrapLength _Call: winId.
        n = 0 ifTrue: [ ^ '' ].
        buf: mutableString copySize: n.
        lib scrapInto _Call: winId With: buf.
        buf ).
    putScrap: s = ( lib putScrap _Call: winId With: s. self ).

    "----- drawing context -----"

    beginDraw = ( lib beginDraw _Call: winId. self ).
    endDraw   = ( lib endDraw   _Call: winId. self ).
    setColorR: r G: g B: b = (
        lib setColor _Call: winId With: r With: g With: b. self ).
    setLineWidth: w = ( lib setLineWidth _Call: winId With: w. self ).
    setFontPx: px Bold: b Italic: i Family: fam = (
        lib setFont _Call: winId With: px With: (b ifTrue: 1 False: 0)
                    With: (i ifTrue: 1 False: 0) With: fam. self ).
    setAlpha: a = ( lib setAlpha _Call: winId With: a. self ).
    setClipX: x Y: y Width: w Height: h = (
        lib setClip _Call: winId With: x With: y With: w With: h. self ).
    clearClip = ( lib clearClip _Call: winId. self ).
    fillRectX: x Y: y Width: w Height: h = (
        lib fillRect _Call: winId With: x With: y With: w With: h. self ).
    strokeRectX: x Y: y Width: w Height: h = (
        lib strokeRect _Call: winId With: x With: y With: w With: h. self ).
    clearRectX: x Y: y Width: w Height: h = (
        lib clearRect _Call: winId With: x With: y With: w With: h. self ).
    drawLineX1: x1 Y1: y1 X2: x2 Y2: y2 = (
        lib drawLine _Call: winId With: x1 With: y1 With: x2 With: y2. self ).
    drawString: s X: x Y: y = (
        lib drawText _Call: winId With: s With: x With: y. self ).
    drawPointX: x Y: y = ( lib drawPoint _Call: winId With: x With: y. self ).
    beginPath = ( lib beginPath _Call: winId. self ).
    moveToX: x Y: y = ( lib moveTo _Call: winId With: x With: y. self ).
    lineToX: x Y: y = ( lib lineTo _Call: winId With: x With: y. self ).
    curveToC1X: c1x C1Y: c1y C2X: c2x C2Y: c2y X: x Y: y = (
        lib curveTo _Call: winId With: c1x With: c1y With: c2x With: c2y
                    With: x With: y. self ).
    closePath = ( lib closePath _Call: winId. self ).
    fill   = ( lib fill   _Call: winId. self ).
    stroke = ( lib stroke _Call: winId. self ).
    arcX: x Y: y Width: w Height: h Start: a1 Span: a2 Fill: f = (
        lib arc _Call: winId With: x With: y With: w With: h With: a1 With: a2
                With: (f ifTrue: 1 False: 0). self ).
    textWidth: s = ( lib textWidth _Call: winId With: s ).

    "----- pixmaps / images -----"

    createPixmapWidth: w Height: h = (
        lib createPixmap _Call: winId With: w With: h ).
    freePixmap: id = ( lib freePixmap _Call: winId With: id. self ).
    setTarget: id = ( lib setTarget _Call: winId With: id. self ).
    copyAreaSrc: src SrcX: sx SrcY: sy Width: w Height: h DstX: dx DstY: dy = (
        lib copyArea _Call: winId With: src With: sx With: sy With: w With: h
                     With: dx With: dy. self ).
    defineImageId: id W: w H: h Indices: idx Palette: pal TransparentIdx: tp = (
        lib defineImage _Call: winId With: id With: w With: h With: idx
                        With: pal With: tp. self ).

    "----- fonts: global tables in the library, receiver ignored (callable
     on the dead prototype, which is how webFont.self uses them) -----"

    registerFont: id Family: fam Bold: b Italic: i = (
        lib ensureLoaded.
        lib registerFont _Call: id With: fam With: (b ifTrue: 1 False: 0)
                         With: (i ifTrue: 1 False: 0). self ).
    textWidthOfFont: id Size: sz String: s = (
        lib fontTextWidth _Call: id With: sz With: s ).
    fontAscentOf: id Size: sz = ( lib fontAscent _Call: id With: sz ).
    fontDescentOf: id Size: sz = ( lib fontDescent _Call: id With: sz ).
    "polled every UI tick, possibly before the desktop (and so the library)
     is up -- answer false rather than failing then"
    consumeFontsRelayout = (
        lib isLoaded ifFalse: [ ^ false ].
        1 = (lib consumeFontsRelayout _CallIfFail: [|:e| error: e]) ).

    "----- seats / viewers -----"

    setSeat: s = ( lib setSeat _Call: winId With: s. self ).
    hasViewer = ( 1 = (lib hasViewer _Call: winId) ).
    isPrimary = ( 1 = (lib isPrimary _Call: winId) ).
    pendingViewers = ( lib pendingViewers _CallIfFail: [|:e| error: e] ).
 | ).
