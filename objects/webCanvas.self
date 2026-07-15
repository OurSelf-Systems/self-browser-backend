 '$Revision: 30.1 $'
 '
Copyright 2026 AUTHORS.
See the LICENSE file for license information.
'

 "webGlobals windowCanvas: the morphic window canvas for the web backend.
  drawable and gc are both the web platformWindow handle (which carries the
  drawing protocol from web.self, over the plugin binding in webPlugin.self).
  Double-buffered: morphs draw into an offscreen
  pixmap (webGlobals bufferCanvas), then pastePixmap blits it to the window."

 '-- Module body'

 bootstrap addSlotsTo: bootstrap stub -> 'globals' -> 'modules' -> () From: ( | {
         'ModuleInfo: Module: webCanvas InitialContents: FollowSlot'
         webCanvas = bootstrap define: bootstrap stub -> 'globals' -> 'modules' -> 'webCanvas' -> () ToBe: bootstrap addSlotsTo: (
             bootstrap remove: 'directory' From:
             bootstrap remove: 'fileInTimeString' From:
             bootstrap remove: 'myComment' From:
             bootstrap remove: 'postFileIn' From:
             bootstrap remove: 'revision' From:
             bootstrap remove: 'subpartNames' From:
             globals modules init copy ) From: bootstrap setObjectAnnotationOf: bootstrap stub -> 'globals' -> 'modules' -> 'webCanvas' -> () From: ( |
             {} = 'ModuleInfo: Creator: globals modules webCanvas.

CopyDowns:
globals modules init. copy
SlotsToOmit: directory fileInTimeString myComment postFileIn revision subpartNames.

\x7fIsComplete: '.
            | ) .
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'globals' -> 'modules' -> 'webCanvas' -> () From: ( | {
         'ModuleInfo: Module: webCanvas InitialContents: FollowSlot\x7fVisibility: public'
         directory <- '../../web-backend-plugin/objects'.
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'globals' -> 'modules' -> 'webCanvas' -> () From: ( | {
         'ModuleInfo: Module: webCanvas InitialContents: InitializeToExpression: (_CurrentTimeString)\x7fVisibility: public'
         fileInTimeString <- _CurrentTimeString.
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'globals' -> 'modules' -> 'webCanvas' -> () From: ( | {
         'ModuleInfo: Module: webCanvas InitialContents: FollowSlot'
         myComment <- ''.
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'globals' -> 'modules' -> 'webCanvas' -> () From: ( | {
         'ModuleInfo: Module: webCanvas InitialContents: FollowSlot'
         postFileIn = ( | | resend.postFileIn).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'globals' -> 'modules' -> 'webCanvas' -> () From: ( | {
         'ModuleInfo: Module: webCanvas InitialContents: FollowSlot\x7fVisibility: public'
         revision <- '$Revision: 30.1 $'.
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'globals' -> 'modules' -> 'webCanvas' -> () From: ( | {
         'ModuleInfo: Module: webCanvas InitialContents: FollowSlot\x7fVisibility: private'
         subpartNames <- ''.
        } | )

 '-- webGlobals windowCanvas'

 bootstrap addSlotsTo: bootstrap stub -> 'globals' -> 'webGlobals' -> () From: ( | {
         'Category: graphical interface\x7fModuleInfo: Module: webCanvas InitialContents: FollowSlot\x7fVisibility: public'
         windowCanvas = bootstrap define: bootstrap stub -> 'globals' -> 'webGlobals' -> 'windowCanvas' -> () ToBe: bootstrap addSlotsTo: (
             bootstrap remove: 'parent' From:
             bootstrap remove: 'platformWindow' From:
             globals abstractWindowCanvas copy ) From: bootstrap setObjectAnnotationOf: bootstrap stub -> 'globals' -> 'webGlobals' -> 'windowCanvas' -> () From: ( |
             {} = 'ModuleInfo: Creator: globals webGlobals windowCanvas.

CopyDowns:
globals abstractWindowCanvas. copy
SlotsToOmit: parent platformWindow.

'.
            | ) .
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'globals' -> 'webGlobals' -> 'windowCanvas' -> () From: ( | {
         'ModuleInfo: Module: webCanvas InitialContents: InitializeToExpression: (0@0)\x7fVisibility: private'
         cachedPosition <- 0@0.
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'globals' -> 'webGlobals' -> 'windowCanvas' -> () From: ( | {
         'ModuleInfo: Module: webCanvas InitialContents: FollowSlot\x7fVisibility: private'
         cachedSize <- (300) @ (200).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'globals' -> 'webGlobals' -> 'windowCanvas' -> () From: ( | {
         'ModuleInfo: Module: webCanvas InitialContents: InitializeToExpression: (x11Globals unmappedPaintManager)'
         colorDict <- bootstrap stub -> 'globals' -> 'x11Globals' -> 'unmappedPaintManager' -> ().
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'globals' -> 'webGlobals' -> 'windowCanvas' -> () From: ( | {
         'ModuleInfo: Module: webCanvas InitialContents: InitializeToExpression: (webGlobals fontDictionary copyRemoveAll)\x7fVisibility: public'
         fontMap <- webGlobals fontDictionary copyRemoveAll.
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'globals' -> 'webGlobals' -> 'windowCanvas' -> () From: ( | {
         'ModuleInfo: Module: webCanvas InitialContents: FollowSlot'
         parent* = bootstrap stub -> 'traits' -> 'webWindowCanvas' -> ().
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'globals' -> 'webGlobals' -> 'windowCanvas' -> () From: ( | {
         'ModuleInfo: Module: webCanvas InitialContents: InitializeToExpression: (web platformWindow deadCopy)\x7fVisibility: public'
         platformWindow <- web platformWindow deadCopy.
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'globals' -> 'webGlobals' -> 'windowCanvas' -> () From: ( | {
         'ModuleInfo: Module: webCanvas InitialContents: InitializeToExpression: (true)\x7fVisibility: public'
         redrawWindow <- bootstrap stub -> 'globals' -> 'true' -> ().
        } | )

 bootstrap addSlotsTo: bootstrap stub -> 'globals' -> 'webGlobals' -> () From: ( | {
         'Category: graphical interface\x7fComment: the display name (with port) the desktop opened on, e.g. \'web:9876\'; reused to add a hand per browser\x7fModuleInfo: Module: webCanvas InitialContents: InitializeToExpression: (\'web:9876\')\x7fVisibility: public'
         webDisplayName <- 'web:9876'.
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'globals' -> 'webGlobals' -> () From: ( | {
         'Category: graphical interface\x7fComment: user names Self wants a window provisioned for on world 1; the UI loop keeps each one provisioned (re-creating it if the snapshot-resume reopen wiped it)\x7fModuleInfo: Module: webCanvas InitialContents: InitializeToExpression: (list copyRemoveAll)\x7fVisibility: public'
         usersToProvision <- list copyRemoveAll.
        } | )

 "State-dedup cache.  Morphic re-asserts the canvas state (color, alpha, font, target)
  on every morph drawOn:, even when nothing changed -- a measurement showed 77% of the
  state opcodes were redundant (target 96%, alpha 89%, font 35%, color 15%).  Skipping
  the prim call at the Self layer avoids Self method dispatch + C glue + the wire byte
  + the JS decode + the canvas2D state-set, all in one hop.  Cache is global because
  the C++ active-window pointer is shared across platformWindows (the spy interleaves
  draws with the desktop).  Cache is reset on a target switch (the browser keeps state
  per-canvas, so the new target's state may differ), but otherwise persists.

  Replay caveat: a viewer that reconnects mid-session receives fb.last (which may be
  sparse because of dedup) followed by an auto-triggered full redraw; any briefly
  incorrect rendering between the two corrects within ~16ms."
 bootstrap addSlotsTo: bootstrap stub -> 'globals' -> 'webGlobals' -> () From: ( | {
         'ModuleInfo: Module: webCanvas InitialContents: FollowSlot\x7fVisibility: public'
         cachedColorR <- nil. cachedColorG <- nil. cachedColorB <- nil.
         cachedAlpha  <- nil.
         cachedFontPx <- nil. cachedFontBold <- nil. cachedFontItal <- nil. cachedFontFam <- nil.
         cachedTarget <- nil.   "either a pixmap id (int) or a platformWindow (object)"
         "Per-canvas state -- color/alpha/font live on the specific canvas2D context, so a
          target switch makes them stale.  Cleared from the ensure* target methods.
          (Uninitialised local `n` defaults to nil -- inside a method on webGlobals the
          bare identifier `nil` doesn't fall through to the global, so this is the cleanest
          way to feed nil to the writer.)"
         invalidatePerCanvasState = ( | n. |
            cachedColorR: n. cachedAlpha: n. cachedFontPx: n. self ).
         "Full reset -- target included.  Fires on every WBE_RESIZE (the resync event for
          reconnect and for actual viewport resize), because the JS client's setDrawableState
          resets the canvas2D state of the resized canvas (line ~65 of web_client.hh) without
          going through an opcode, so our cache would otherwise lie about the browser state."
         invalidateStateCache = ( | n. |
            invalidatePerCanvasState. cachedTarget: n. self ).
        } | )

 "Dedup-aware wrappers around the state-setting prims.  Each ensure* compares the new
  value against webGlobals' cached one; on a match it returns without calling the
  underlying prim (no Self -> C glue, no opcode, no canvas2D state-set on the client).
  invalidatePerCanvasState clears the per-canvas state cache fields because canvas2D
  state lives on the specific drawable -- a target switch makes the cached color/font/
  alpha irrelevant for the new target."
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'web' -> 'platformWindow' -> () From: ( | {
         'Category: gc\x7fModuleInfo: Module: webCanvas InitialContents: FollowSlot\x7fVisibility: public'
         ensureColorR: r G: g B: b = ( |
            | ((webGlobals cachedColorR = r) && [webGlobals cachedColorG = g] && [webGlobals cachedColorB = b])
                 ifFalse: [ setColorR: r G: g B: b.
                            webGlobals cachedColorR: r. webGlobals cachedColorG: g. webGlobals cachedColorB: b ].
              self).
         ensureAlpha: a = ( |
            | webGlobals cachedAlpha = a
                 ifFalse: [ setAlpha: a. webGlobals cachedAlpha: a ].
              self).
         ensureFontPx: p Bold: b Italic: i Family: f = ( |
            | ((webGlobals cachedFontPx = p) && [webGlobals cachedFontBold = b]
                 && [webGlobals cachedFontItal = i] && [webGlobals cachedFontFam = f])
                 ifFalse: [ setFontPx: p Bold: b Italic: i Family: f.
                            webGlobals cachedFontPx: p. webGlobals cachedFontBold: b.
                            webGlobals cachedFontItal: i. webGlobals cachedFontFam: f ].
              self).
         "Target dedup: pixmap (id) variant.  On a switch, invalidate per-canvas state."
         ensureTargetIs: id = ( |
            | webGlobals cachedTarget = id
                 ifFalse: [ setTarget: id. webGlobals cachedTarget: id. webGlobals invalidatePerCanvasState ].
              self).
         "Target dedup: window variant.  beginDraw in the prim sets target to MY
          windowId; cache the platformWindow object itself as the discriminator."
         ensureBeginDraw = ( |
            | webGlobals cachedTarget == self
                 ifFalse: [ beginDraw. webGlobals cachedTarget: self. webGlobals invalidatePerCanvasState ].
              self).
        } | )

 '-- traits webWindowCanvas'

 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> () From: ( | {
         'Category: graphical interface\x7fModuleInfo: Module: webCanvas InitialContents: FollowSlot\x7fVisibility: public'
         webWindowCanvas = bootstrap setObjectAnnotationOf: bootstrap stub -> 'traits' -> 'webWindowCanvas' -> () From: ( |
             {} = 'ModuleInfo: Creator: traits webWindowCanvas.
'.
            | ) .
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webWindowCanvas' -> () From: ( | {
         'ModuleInfo: Module: webCanvas InitialContents: FollowSlot\x7fVisibility: private'
         parent* = bootstrap stub -> 'traits' -> 'abstractWindowCanvas' -> ().
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webWindowCanvas' -> () From: ( | {
         'Category: opening and closing\x7fModuleInfo: Module: webCanvas InitialContents: FollowSlot\x7fVisibility: public'
         close = ( | | platformWindow basicClose. self).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webWindowCanvas' -> () From: ( | {
         'Category: portable accessing\x7fComment: re-target the stream to this window\x7fModuleInfo: Module: webCanvas InitialContents: FollowSlot\x7fVisibility: public'
         drawable = ( | | platformWindow ensureBeginDraw. platformWindow).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webWindowCanvas' -> () From: ( | {
         'Category: accessing\x7fModuleInfo: Module: webCanvas InitialContents: FollowSlot\x7fVisibility: public'
         gc = ( | | platformWindow ensureBeginDraw. platformWindow).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webWindowCanvas' -> () From: ( | {
         'Category: accessing\x7fModuleInfo: Module: webCanvas InitialContents: FollowSlot\x7fVisibility: public'
         window = ( | | platformWindow).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webWindowCanvas' -> () From: ( | {
         'Category: drawing\x7fModuleInfo: Module: webCanvas InitialContents: FollowSlot\x7fVisibility: public'
         indexForColor: c = ( | | c).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webWindowCanvas' -> () From: ( | {
         'Category: drawing\x7fComment: true if any (coord + off) lands beyond the web protocol\'s 16-bit range. Two-sided comparison (no abs) works on bigInts, so it never trips the asSmallInteger that the inherited fillPolygonXs:Ys:Color: uses.\x7fModuleInfo: Module: webCanvas InitialContents: FollowSlot\x7fVisibility: private'
         anyBeyondI16: list Offset: off = ( |
            |
            list do: [| :v. s | s: v + off. ((s > 32000) || [s < (0 - 32000)]) ifTrue: [ ^true ] ].
            false).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webWindowCanvas' -> () From: ( | {
         'Category: drawing\x7fComment: A morph parked entirely off-screen at minSmallInt (e.g. the factory window before the hand repositions it) produces bezel-polygon coordinates whose transformed value overflows smallInt, and the inherited method\'s asSmallInteger then raises "doesn\'t fit into small integer". Such a polygon is wholly off-screen, so skip it; on-screen polygons resend unchanged -- no clamping, so on-screen geometry (including partially off-screen morphs within i16 range) is never distorted.\x7fModuleInfo: Module: webCanvas InitialContents: FollowSlot\x7fVisibility: public'
         fillPolygonXs: xList Ys: yList Color: c = ( |
            |
            (anyBeyondI16: xList Offset: offset x) ifTrue: [ ^self ].
            (anyBeyondI16: yList Offset: offset y) ifTrue: [ ^self ].
            resend.fillPolygonXs: xList Ys: yList Color: c).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webWindowCanvas' -> () From: ( | {
         'Category: drawing\x7fModuleInfo: Module: webCanvas InitialContents: FollowSlot\x7fVisibility: public'
         grayMask = ( | | nil).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webWindowCanvas' -> () From: ( | {
         'Category: drawing\x7fComment: bitmap clip masks unsupported on web; just draw unmasked (the inherited withMask:Offset:Do: derefs m pixMap which can be nil)\x7fModuleInfo: Module: webCanvas InitialContents: FollowSlot\x7fVisibility: public'
         withMask: m Offset: o Do: blk = ( | | blk value. self).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webWindowCanvas' -> () From: ( | {
         'Category: drawing\x7fComment: real alpha instead of a stipple grayMask (the inherited translucentlyDo: -> withPattern: grayMask -> nil pixMap)\x7fModuleInfo: Module: webCanvas InitialContents: FollowSlot\x7fVisibility: public'
         translucentlyDo: blk = ( | | gc ensureAlpha: 128. blk value. gc ensureAlpha: 255. self).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webWindowCanvas' -> () From: ( | {
         'Category: drawing\x7fComment: web has no stipple patterns; draw solid\x7fModuleInfo: Module: webCanvas InitialContents: FollowSlot\x7fVisibility: public'
         withPattern: p Do: blk = ( | | blk value. self).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webWindowCanvas' -> () From: ( | {
         'Category: opening and closing\x7fModuleInfo: Module: webCanvas InitialContents: FollowSlot\x7fVisibility: public'
         isOpen = ( | | platformWindow ifNil: false IfNotNil: [|:w| w raw_isOpen]).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webWindowCanvas' -> () From: ( | {
         'Category: positioning and sizing\x7fModuleInfo: Module: webCanvas InitialContents: FollowSlot\x7fVisibility: public'
         size = ( | | isOpen ifTrue: [platformWindow width @ platformWindow height] False: [cachedSize]).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webWindowCanvas' -> () From: ( | {
         'Category: positioning and sizing\x7fModuleInfo: Module: webCanvas InitialContents: FollowSlot\x7fVisibility: public'
         size: pt = ( | | cachedSize: pt. self).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webWindowCanvas' -> () From: ( | {
         'Category: positioning and sizing\x7fModuleInfo: Module: webCanvas InitialContents: FollowSlot\x7fVisibility: public'
         position = ( | | cachedPosition).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webWindowCanvas' -> () From: ( | {
         'Category: positioning and sizing\x7fModuleInfo: Module: webCanvas InitialContents: FollowSlot\x7fVisibility: public'
         position: pt = ( | | cachedPosition: pt. self).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webWindowCanvas' -> () From: ( | {
         'Category: positioning and sizing\x7fModuleInfo: Module: webCanvas InitialContents: FollowSlot\x7fVisibility: public'
         innerOriginOffsetFromBorder = ( | | 0@0).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webWindowCanvas' -> () From: ( | {
         'Category: positioning and sizing\x7fModuleInfo: Module: webCanvas InitialContents: FollowSlot\x7fVisibility: public'
         innerPosition = ( | | position + innerOriginOffsetFromBorder).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webWindowCanvas' -> () From: ( | {
         'Category: decoding update events\x7fModuleInfo: Module: webCanvas InitialContents: FollowSlot\x7fVisibility: public'
         hasSizeChanged = ( | | cachedSize != (platformWindow width @ platformWindow height)).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webWindowCanvas' -> () From: ( | {
         'Category: accessing\x7fModuleInfo: Module: webCanvas InitialContents: FollowSlot\x7fVisibility: public'
         display = ( | | platformWindow).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webWindowCanvas' -> () From: ( | {
         'Category: accessing\x7fModuleInfo: Module: webCanvas InitialContents: FollowSlot\x7fVisibility: public'
         displayName = ( | | 'web').
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webWindowCanvas' -> () From: ( | {
         'Category: events\x7fModuleInfo: Module: webCanvas InitialContents: FollowSlot\x7fVisibility: public'
         eventsPending = ( | |
            "Font metrics are measured asynchronously in the browser; labels first laid
             out with the pre-calibration estimate have stale width caches.  When fresh
             metrics arrive, flush every morph's cached width so it re-measures."
            web platformWindow consumeFontsRelayout ifTrue: [
               desktop worlds do: [| :w | w allMorphsDo: [| :m | m worldHasReopened]].
            ].
            "Keep the Self-configured windows provisioned. Browsers never create windows on
             connect (they only attach by seat); Self decides who gets how many. Re-provision
             if the snapshot-resume reopen has wiped them. Base canvas only, once per poll."
            (desktop worlds isEmpty not && [self == (desktop worlds first winCanvases first)])
               ifTrue: [ "Also drain the plugin's mail doorbell here: the library rings
                          it when input arrives, but this loop polls, so the ring is
                          only a wake-up hint -- drain it so the pipe never sits full."
                         nil _MailFlagCheckAndClear.
                         desktop ensureProvisionedWindows ].
            "Apply any view-pan the browser accumulated for this window: pan moves the
             Morphic world under the view (wc/bc offset), so morphs outside the old view
             get drawn as they scroll in -- the browser cannot do this, it only has what
             was already painted."
            applyPendingViewPan.
            platformWindow eventsPending).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webWindowCanvas' -> () From: ( | {
         'Category: events\x7fComment: Drain the browser-accumulated view-pan (world units) for this window and scroll this view\'s hand by it via the standard worldMorph moveHand:InWorldBy: (same path radarView uses).\x7fModuleInfo: Module: webCanvas InitialContents: FollowSlot\x7fVisibility: public'
         applyPendingViewPan = ( |
             dx. dy. |
            dx: platformWindow takePanX.
            dy: platformWindow takePanY.
            ((dx = 0) && [dy = 0]) ifTrue: [ ^self ].
            desktop worlds do: [| :w. h |
               (w winCanvases includes: self) ifTrue: [
                  h: w handForWinCanvas: self IfAbsent: nil.
                  h ifNotNil: [ w moveHand: h InWorldBy: (dx @ dy) ].
               ].
            ].
            self).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webWindowCanvas' -> () From: ( | {
         'Category: events\x7fModuleInfo: Module: webCanvas InitialContents: FollowSlot\x7fVisibility: public'
         ui2Event = ( | | x11Globals ui2Event).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webWindowCanvas' -> () From: ( | {
         'Category: events\x7fModuleInfo: Module: webCanvas InitialContents: FollowSlot\x7fVisibility: public'
         nextEvent = ( | | webGlobals webRawEvent copyFromWindow: platformWindow Popping: true).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webWindowCanvas' -> () From: ( | {
         'Category: events\x7fModuleInfo: Module: webCanvas InitialContents: FollowSlot\x7fVisibility: public'
         peekEvent = ( | | webGlobals webRawEvent copyFromWindow: platformWindow Popping: false).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webWindowCanvas' -> () From: ( | {
         'Category: portable accessing\x7fModuleInfo: Module: webCanvas InitialContents: FollowSlot\x7fVisibility: public'
         pixmapCanvasPrototypeForMyScreen = ( | | webGlobals bufferCanvas).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webWindowCanvas' -> () From: ( | {
         'Category: pixelCopying\x7fComment: Blit a pixmap region to this window in one COPY_AREA. The base canvas threads the source through `aPixmapCanvas drawable copyArea:...`, but on web every drawable is the one platformWindow and the source is a pixmap *id*, so override to emit copyAreaSrc: directly. Set the target to this window first (beginDraw), then copy from the pixmap id; mirrors the base pastePixmap coordinates (transformPt: for the dest, src as-is).\x7fModuleInfo: Module: webCanvas InitialContents: FollowSlot\x7fVisibility: public'
         pastePixmap: aPixmapCanvas At: dst Src: src Width: w Height: h = ( |
             d.
            |
            d: transformPt: dst.
            platformWindow ensureBeginDraw.
            platformWindow copyAreaSrc: aPixmapCanvas pixmapIdForCopy
                SrcX:   src x   SrcY:   src y
                Width:  w       Height: h
                DstX:   d x     DstY:   d y.
            self).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webWindowCanvas' -> () From: ( | {
         'Category: opening and closing\x7fModuleInfo: Module: webCanvas InitialContents: FollowSlot\x7fVisibility: public'
         openForWorld: wld OnDisplay: displayNm At: pt Width: w Height: h = ( |
            |
            "Double-buffer: morphs draw into an offscreen pixmap, then pastePixmap blits
             the finished region to the window in one COPY_AREA -- so the browser never
             shows a half-drawn frame (partial command flushes land on the pixmap)."
            wld doubleBuffering: true.
            webGlobals webDisplayName: displayNm.   "reused to add a hand per browser viewer"
            platformWindow: web platformWindow new.
            platformWindow openDisplay: displayNm
                Left: pt x Top: pt y Width: w Height: h
                MinWidth: w MaxWidth: w MinHeight: h MaxHeight: h
                WindowName: wld name IconName: wld name
                FontName: 'monospace' FontSize: 13.
            cachedPosition: pt.
            cachedSize: w @ h.
            fontMap: fontMap copyRemoveAll.
            self).
        } | )

 '-- image cache entry prototype (pixmap + optional mask + lastUsed).  The
    inherited abstractWindowCanvas pixmapAndMaskFor:/updatePixmapCacheEntry:
    clones this and fills it via pixmapCanvasPrototypeForMyScreen (bufferCanvas).'

 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webWindowCanvas' -> () From: ( | {
         'Category: image support\x7fModuleInfo: Module: webCanvas InitialContents: FollowSlot\x7fVisibility: private'
         pixmapCacheEntry = bootstrap setObjectAnnotationOf: bootstrap stub -> 'traits' -> 'webWindowCanvas' -> 'pixmapCacheEntry' -> () From: ( |
             {} = 'ModuleInfo: Creator: traits webWindowCanvas pixmapCacheEntry.
'.
            | ) .
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webWindowCanvas' -> 'pixmapCacheEntry' -> () From: ( | {
         'ModuleInfo: Module: webCanvas InitialContents: FollowSlot'
         parent* = bootstrap stub -> 'traits' -> 'clonable' -> ().
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webWindowCanvas' -> 'pixmapCacheEntry' -> () From: ( | {
         'ModuleInfo: Module: webCanvas InitialContents: InitializeToExpression: (webGlobals bufferCanvas)\x7fVisibility: public'
         pixmap <- bootstrap stub -> 'globals' -> 'webGlobals' -> 'bufferCanvas' -> ().
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webWindowCanvas' -> 'pixmapCacheEntry' -> () From: ( | {
         'ModuleInfo: Module: webCanvas InitialContents: InitializeToExpression: (webGlobals bufferCanvas)\x7fVisibility: public'
         mask <- bootstrap stub -> 'globals' -> 'webGlobals' -> 'bufferCanvas' -> ().
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webWindowCanvas' -> 'pixmapCacheEntry' -> () From: ( | {
         'ModuleInfo: Module: webCanvas InitialContents: InitializeToExpression: (0)\x7fVisibility: public'
         lastUsed <- 0.
        } | )

 '-- webGlobals bufferCanvas: an offscreen pixmap canvas (for double-buffering,
    grayMask, and image caching).  Drawing re-targets the shared command stream
    to this pixmap; pastePixmap/copyArea blits it to the window.'

 bootstrap addSlotsTo: bootstrap stub -> 'globals' -> 'webGlobals' -> () From: ( | {
         'Category: graphical interface\x7fModuleInfo: Module: webCanvas InitialContents: FollowSlot\x7fVisibility: public'
         bufferCanvas = bootstrap define: bootstrap stub -> 'globals' -> 'webGlobals' -> 'bufferCanvas' -> () ToBe: bootstrap addSlotsTo: (
             bootstrap remove: 'parent' From:
             globals abstractPixmapCanvas copy ) From: bootstrap setObjectAnnotationOf: bootstrap stub -> 'globals' -> 'webGlobals' -> 'bufferCanvas' -> () From: ( |
             {} = 'ModuleInfo: Creator: globals webGlobals bufferCanvas.

CopyDowns:
globals abstractPixmapCanvas. copy
SlotsToOmit: parent.

'.
            | ) .
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'globals' -> 'webGlobals' -> 'bufferCanvas' -> () From: ( | {
         'ModuleInfo: Module: webCanvas InitialContents: InitializeToExpression: (nil)'
         winCanvas.
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'globals' -> 'webGlobals' -> 'bufferCanvas' -> () From: ( | {
         'ModuleInfo: Module: webCanvas InitialContents: InitializeToExpression: (0)'
         pixmapId <- 0.
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'globals' -> 'webGlobals' -> 'bufferCanvas' -> () From: ( | {
         'ModuleInfo: Module: webCanvas InitialContents: InitializeToExpression: (1@1)'
         cachedSize <- 1@1.
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'globals' -> 'webGlobals' -> 'bufferCanvas' -> () From: ( | {
         'ModuleInfo: Module: webCanvas InitialContents: FollowSlot'
         parent* = bootstrap stub -> 'traits' -> 'webPixmapCanvas' -> ().
        } | )

 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> () From: ( | {
         'Category: graphical interface\x7fModuleInfo: Module: webCanvas InitialContents: FollowSlot\x7fVisibility: public'
         webPixmapCanvas = bootstrap setObjectAnnotationOf: bootstrap stub -> 'traits' -> 'webPixmapCanvas' -> () From: ( |
             {} = 'ModuleInfo: Creator: traits webPixmapCanvas.
'.
            | ) .
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webPixmapCanvas' -> () From: ( | {
         'ModuleInfo: Module: webCanvas InitialContents: FollowSlot\x7fVisibility: private'
         parent* = bootstrap stub -> 'traits' -> 'abstractPixmapCanvas' -> ().
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webPixmapCanvas' -> () From: ( | {
         'Category: creation\x7fModuleInfo: Module: webCanvas InitialContents: FollowSlot\x7fVisibility: private'
         initForSameScreenAs: aWindowCanvas Width: w Height: h Depth: d = ( |
            |
            winCanvas: aWindowCanvas.
            cachedSize: (w max: 1) @ (h max: 1).
            pixmapId: aWindowCanvas platformWindow createPixmapWidth: (w max: 1) Height: (h max: 1).
            self).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webPixmapCanvas' -> () From: ( | {
         'Category: basics\x7fComment: re-target the stream to this pixmap before drawing\x7fModuleInfo: Module: webCanvas InitialContents: FollowSlot\x7fVisibility: public'
         drawable = ( | | winCanvas platformWindow ensureTargetIs: pixmapId. winCanvas platformWindow).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webPixmapCanvas' -> () From: ( | {
         'Category: basics\x7fModuleInfo: Module: webCanvas InitialContents: FollowSlot\x7fVisibility: public'
         gc = ( | | winCanvas platformWindow ensureTargetIs: pixmapId. winCanvas platformWindow).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webPixmapCanvas' -> () From: ( | {
         'Category: accessing\x7fModuleInfo: Module: webCanvas InitialContents: FollowSlot\x7fVisibility: public'
         pixMap = ( | | self).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webPixmapCanvas' -> () From: ( | {
         'Category: accessing\x7fModuleInfo: Module: webCanvas InitialContents: FollowSlot\x7fVisibility: public'
         pixmapIdForCopy = ( | | pixmapId).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webPixmapCanvas' -> () From: ( | {
         'Category: accessing\x7fModuleInfo: Module: webCanvas InitialContents: FollowSlot\x7fVisibility: public'
         size = ( | | cachedSize).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webPixmapCanvas' -> () From: ( | {
         'Category: accessing\x7fModuleInfo: Module: webCanvas InitialContents: FollowSlot\x7fVisibility: public'
         depth = ( | | 32).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webPixmapCanvas' -> () From: ( | {
         'Category: accessing\x7fModuleInfo: Module: webCanvas InitialContents: FollowSlot\x7fVisibility: public'
         screen = ( | | self).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webPixmapCanvas' -> () From: ( | {
         'Category: opening and closing\x7fModuleInfo: Module: webCanvas InitialContents: FollowSlot\x7fVisibility: public'
         isOpen = ( | | pixmapId > 0).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webPixmapCanvas' -> () From: ( | {
         'Category: opening and closing\x7fModuleInfo: Module: webCanvas InitialContents: FollowSlot\x7fVisibility: public'
         close = ( | | (pixmapId > 0) ifTrue: [winCanvas platformWindow freePixmap: pixmapId. pixmapId: 0]. self).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webPixmapCanvas' -> () From: ( | {
         'Category: converting ui2Images\x7fComment: Load an indexed ui2Image into this (already-created, image-sized) pixmap: build an rgb palette from its colours and hand the raw index bytes to the C++ side, which expands them to RGBA (transparentPixelValue -> alpha 0) and writes WB_DEFINE_IMAGE into the pixmap; the cache then blits it like any pixmap.\x7fModuleInfo: Module: webCanvas InitialContents: FollowSlot\x7fVisibility: public'
         drawFromImage: im = ( |
             w. h. pal. tp. cs. |
            w: im width.  h: im height.
            ((w * h) = 0) ifTrue: [ ^self ].
            cs: im colors.
            pal: byteVector copySize: cs size * 3.
            cs size do: [| :i. c. j |
               c: cs at: i.  j: i * 3.
               pal at: j     Put: c   redForQuartz.
               pal at: (j + 1) Put: c greenForQuartz.
               pal at: (j + 2) Put: c  blueForQuartz.
            ].
            tp: im masked ifTrue: [ im transparentPixelValue ] False: [ 0 - 1 ].
            winCanvas platformWindow defineImageId: pixmapId W: w H: h
               Indices: im pixelData Palette: pal TransparentIdx: tp.
            self).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webPixmapCanvas' -> () From: ( | {
         'Category: converting ui2Images\x7fModuleInfo: Module: webCanvas InitialContents: FollowSlot\x7fVisibility: public'
         drawMaskFromImage: im = ( | | self).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webPixmapCanvas' -> () From: ( | {
         'Category: pixelCopying\x7fComment: Blit a pixmap region into THIS pixmap (the double-buffer target) in one COPY_AREA. Mirrors the webWindowCanvas override but targets this pixmap (via gc -> setTarget: pixmapId) instead of the window, so an image pasted by a morph lands in the buffer (the base pastePixmap: routes through drawable copyArea:To:At:GC: which the web backend does not emit).\x7fModuleInfo: Module: webCanvas InitialContents: FollowSlot\x7fVisibility: public'
         pastePixmap: aPixmapCanvas At: dst Src: src Width: w Height: h = ( |
             d. |
            d: transformPt: dst.
            gc copyAreaSrc: aPixmapCanvas pixmapIdForCopy
                SrcX:   src x   SrcY:   src y
                Width:  w       Height: h
                DstX:   d x     DstY:   d y.
            self).
        } | )

 '-- Drawing-behaviour overrides mirroring webWindowCanvas, needed because with
    double-buffering morphs draw into this pixmap (not the window).  Web has no
    stipple grayMask, so the base translucentlyDo:/withPattern:/withMask: deref a
    nil pixMap -- use real alpha / no-ops instead.'

 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webPixmapCanvas' -> () From: ( | {
         'Category: drawing\x7fModuleInfo: Module: webCanvas InitialContents: FollowSlot\x7fVisibility: public'
         translucentlyDo: blk = ( | | gc ensureAlpha: 128. blk value. gc ensureAlpha: 255. self).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webPixmapCanvas' -> () From: ( | {
         'Category: drawing\x7fModuleInfo: Module: webCanvas InitialContents: FollowSlot\x7fVisibility: public'
         withPattern: p Do: blk = ( | | blk value. self).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webPixmapCanvas' -> () From: ( | {
         'Category: drawing\x7fModuleInfo: Module: webCanvas InitialContents: FollowSlot\x7fVisibility: public'
         withMask: m Offset: o Do: blk = ( | | blk value. self).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webPixmapCanvas' -> () From: ( | {
         'Category: drawing\x7fModuleInfo: Module: webCanvas InitialContents: FollowSlot\x7fVisibility: public'
         grayMask = ( | | nil).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webPixmapCanvas' -> () From: ( | {
         'Category: drawing\x7fComment: skip a polygon wholly beyond the 16-bit protocol range so the inherited asSmallInteger never trips on an off-screen morph (mirrors webWindowCanvas)\x7fModuleInfo: Module: webCanvas InitialContents: FollowSlot\x7fVisibility: private'
         anyBeyondI16: list Offset: off = ( |
            |
            list do: [| :v. s | s: v + off. ((s > 32000) || [s < (0 - 32000)]) ifTrue: [ ^true ] ].
            false).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webPixmapCanvas' -> () From: ( | {
         'Category: drawing\x7fModuleInfo: Module: webCanvas InitialContents: FollowSlot\x7fVisibility: public'
         fillPolygonXs: xList Ys: yList Color: c = ( |
            |
            (anyBeyondI16: xList Offset: offset x) ifTrue: [ ^self ].
            (anyBeyondI16: yList Offset: offset y) ifTrue: [ ^self ].
            resend.fillPolygonXs: xList Ys: yList Color: c).
        } | )

 '-- Side effects'

 "On macOS the inherited platformSpecificNameFor: always returns 'quartz', which the
  world's reopen (after snapshot resume) would use to re-open the desktop -- dropping
  the web port and landing every window on the default server. For the web build, the
  display name (with port) is authoritative, so a reopened window stays on the same
  server as the rest and keeps one server for all hands."
 traits worldMorph _AddSlots: ( | platformSpecificNameFor: dn = ( webGlobals webDisplayName ) | ).

 "Web is the sole GUI backend in a SELF_WEB build: route every window canvas to the web
  one regardless of host osName (the quartz/x11 globals are never exercised here)."
 traits worldMorph _AddSlots: ( | windowCanvasPrototypeForDisplay: dispName = ( webGlobals windowCanvas ) | ).

 "Clipboard: the editor's ui2_textBuffer syncs through the platform window's
  storeToClipboard:/fetchFromClipboard.  getScrap/putScrap: keep a per-seat scrap so in-Self
  copy/paste works; putScrap: also pushes the bytes to the browser, which writes the viewer's
  real OS clipboard.  Paste of external text comes in as injected input via the browser's
  paste event, so fetchFromClipboard only needs to return the in-Self scrap here."
 traits web platformWindow _AddSlots: ( |
   fetchFromClipboard          = ( getScrap ).
   fetchFromClipboardIfFail: fb = ( getScrap ).
   storeToClipboard: s          = ( putScrap: s. s ).
   storeToClipboard: s IfFail: fb = ( putScrap: s. s ) | ).

 "Convenience entry point: open the Self desktop in the browser on the given listen spec.
  The spec is a civetweb listening_ports value -- a comma list of port / ip:port / [ipv6]:port
  / +port (v4+v6) / x<path> (unix socket), e.g. '9876' or '127.0.0.1:9876,[::1]:9876'.
  `spec` is a string.  Sets the display name the rest of the backend keys off."
 desktop _AddSlots: ( |
   openOnWeb: spec = ( |
       dn. |
      dn: 'web:', spec.
      webGlobals webDisplayName: dn.
      openOnDisplay: dn ).
   "Open the web desktop using the listen spec from the environment: SELF_WEB_LISTEN (a full
    spec), else SELF_WEB_PORT (a bare port), else 9876.  Registered as a scheduler-initial
    message in a baked web snapshot so `Self -s web.snap64` opens fresh on resume -- opening
    fresh (not reopening a saved-open desktop) avoids the dead C++ window proxies a resumed
    snapshot would otherwise carry."
   openWebFromEnv = ( |
       spec. |
      spec: os environmentAt: 'SELF_WEB_LISTEN'
               IfFail: [ os environmentAt: 'SELF_WEB_PORT' IfFail: '9876' ].
      openOnWeb: spec ) | ).

 "Provision a hand+window for an existing user on an existing world, and label the new
  window with its seat (userName/worldIndex/windowIndex). A browser then attaches by
  visiting that URL (/userName/worldIndex/windowIndex); nothing is created on connect."
 desktop _AddSlots: ( |
   provisionWindowForUser: userName OnWorld: worldIdx = ( |
       wld. wc. h. profile. |
      "create a window+hand on the world and assign its hand to the user; the seat label
       is applied uniformly by ensureProvisionedWindows (so the owner base looks the same)."
      wld: worlds at: worldIdx IfAbsent: [^ error: 'no such world: ', worldIdx printString].
      profile: users owner.
      users team do: [| :u | u name = userName ifTrue: [profile: u] ].
      wld addWindowOnDisplay: webGlobals webDisplayName Bounds: ((0@0) ## (800@600)).
      wc: wld winCanvases last.
      h: wld handForWinCanvas: wc IfAbsent: nil.
      h ifNotNil: [ h userInfo: profile ].
      self ).
   ensureProvisionedWindows = ( |
       wIdx. |
      "1. keep each configured user holding `count` windows on its world (usersToProvision
       is a list of (userName, worldIndex, count) vectors); re-provision after a reopen."
      webGlobals usersToProvision do: [| :spec. userName. worldIdx. count. wld. have |
         userName: spec at: 0. worldIdx: spec at: 1. count: spec at: 2.
         wld: worlds at: worldIdx IfAbsent: [nil].
         wld ifNotNil: [
            have: 0.
            wld winCanvases do: [| :wc. hh |
               hh: wld handForWinCanvas: wc IfAbsent: nil.
               (hh isNotNil && [hh userInfo name = userName]) ifTrue: [have: have + 1].
            ].
            [have < count] whileTrue: [
               provisionWindowForUser: userName OnWorld: worldIdx. have: have + 1.
            ].
         ].
      ].
      "2. label EVERY window by its hand user and position (user/world/display) so the
       owner base seat looks exactly like any other -- root has no special back-door."
      wIdx: 0.
      worlds do: [| :wld. iIdx |
         iIdx: 0.
         wld winCanvases do: [| :wc. hh. uname |
            hh: wld handForWinCanvas: wc IfAbsent: nil.
            uname: 'owner'.
            hh ifNotNil: [| :h | uname: h userInfo name].
            wc platformWindow setSeat: (uname, '/', wIdx printString, '/', iIdx printString).
            iIdx: iIdx + 1.
         ].
         wIdx: wIdx + 1.
      ].
      self ).
 | ).

 globals modules webCanvas postFileIn
