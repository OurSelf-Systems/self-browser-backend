 '$Revision: 30.1 $'
 '
Copyright 2026 AUTHORS.
See the LICENSE file for license information.
'

 "The web (browser) graphics backend.  `web platformWindow` is a handle for a
  WebWindow inside the web oop-library plugin (libweb, this repo): it is BOTH the
  platform window (open/close/resize/events) AND the drawing surface + graphics
  context.  The plugin binding (webPlugin.self) adds the raw wrappers
  (setColorR:G:B:, fillRectX:Y:Width:Height:, beginDraw, eventX, ...) to
  `traits web platformWindow`, each a _Call through the plugin's fctProxies
  keyed by the window's small-integer id (winId); this file adds the morphic
  canvas DRAWABLE and CONTEXT protocols on top, delegating to those raw
  wrappers."

 '-- Module body'

 bootstrap addSlotsTo: bootstrap stub -> 'globals' -> 'modules' -> () From: ( | {
         'ModuleInfo: Module: web InitialContents: FollowSlot'

         web = bootstrap define: bootstrap stub -> 'globals' -> 'modules' -> 'web' -> () ToBe: bootstrap addSlotsTo: (
             bootstrap remove: 'directory' From:
             bootstrap remove: 'fileInTimeString' From:
             bootstrap remove: 'myComment' From:
             bootstrap remove: 'postFileIn' From:
             bootstrap remove: 'revision' From:
             bootstrap remove: 'subpartNames' From:
             globals modules init copy ) From: bootstrap setObjectAnnotationOf: bootstrap stub -> 'globals' -> 'modules' -> 'web' -> () From: ( |
             {} = 'ModuleInfo: Creator: globals modules web.

CopyDowns:
globals modules init. copy
SlotsToOmit: directory fileInTimeString myComment postFileIn revision subpartNames.

\x7fIsComplete: '.
            | ) .
        } | )

 bootstrap addSlotsTo: bootstrap stub -> 'globals' -> 'modules' -> 'web' -> () From: ( | {
         'ModuleInfo: Module: web InitialContents: FollowSlot\x7fVisibility: public'
         directory <- '../../web-backend-plugin/objects'.
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'globals' -> 'modules' -> 'web' -> () From: ( | {
         'ModuleInfo: Module: web InitialContents: InitializeToExpression: (_CurrentTimeString)\x7fVisibility: public'
         fileInTimeString <- _CurrentTimeString.
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'globals' -> 'modules' -> 'web' -> () From: ( | {
         'ModuleInfo: Module: web InitialContents: FollowSlot'
         myComment <- ''.
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'globals' -> 'modules' -> 'web' -> () From: ( | {
         'ModuleInfo: Module: web InitialContents: FollowSlot'
         postFileIn = ( | | resend.postFileIn).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'globals' -> 'modules' -> 'web' -> () From: ( | {
         'ModuleInfo: Module: web InitialContents: FollowSlot\x7fVisibility: public'
         revision <- '$Revision: 30.1 $'.
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'globals' -> 'modules' -> 'web' -> () From: ( | {
         'ModuleInfo: Module: web InitialContents: FollowSlot\x7fVisibility: private'
         subpartNames <- ''.
        } | )

 '-- The web namespace + platformWindow proxy prototype'

 bootstrap addSlotsTo: bootstrap stub -> 'globals' -> () From: ( | {
         'Category: graphical interface\x7fModuleInfo: Module: web InitialContents: FollowSlot\x7fVisibility: public'
         web = bootstrap setObjectAnnotationOf: bootstrap stub -> 'globals' -> 'web' -> () From: ( |
             {} = 'ModuleInfo: Creator: globals web.
'.
            | ) .
        } | )

 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> () From: ( | {
         'Category: graphical interface\x7fModuleInfo: Module: web InitialContents: FollowSlot\x7fVisibility: public'
         web = bootstrap setObjectAnnotationOf: bootstrap stub -> 'traits' -> 'web' -> () From: ( |
             {} = 'ModuleInfo: Creator: traits web.
'.
            | ) .
        } | )

 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'web' -> () From: ( | {
         'ModuleInfo: Module: web InitialContents: FollowSlot\x7fVisibility: public'
         platformWindow = bootstrap setObjectAnnotationOf: bootstrap stub -> 'traits' -> 'web' -> 'platformWindow' -> () From: ( |
             {} = 'ModuleInfo: Creator: traits web platformWindow.
'.
            | ) .
        } | )

 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'web' -> 'platformWindow' -> () From: ( | {
         'Comment: inherit abstractDrawable (whose parent is traits proxy) so we
get the drawable helper/width/dashed variants (drawRectangle:Width:GC:,
drawLine:To:Width:GC:, ...) for free while our own slots override the rest.\x7fModuleInfo: Module: web InitialContents: FollowSlot'
         parent* = bootstrap stub -> 'traits' -> 'abstractDrawable' -> ().
        } | )

 bootstrap addSlotsTo: bootstrap stub -> 'globals' -> 'web' -> () From: ( | {
         'Category: graphical interface\x7fModuleInfo: Module: web InitialContents: FollowSlot\x7fVisibility: public'
         platformWindow = bootstrap setObjectAnnotationOf: bootstrap stub -> 'globals' -> 'web' -> 'platformWindow' -> () From: ( |
             {} = 'ModuleInfo: Creator: globals web platformWindow.
'.
            | ) .
        } | )

 bootstrap addSlotsTo: bootstrap stub -> 'globals' -> 'web' -> 'platformWindow' -> () From: ( | {
         'ModuleInfo: Module: web InitialContents: FollowSlot'
         parent* = bootstrap stub -> 'traits' -> 'web' -> 'platformWindow' -> ().
        } | )

 bootstrap addSlotsTo: bootstrap stub -> 'globals' -> 'web' -> 'platformWindow' -> () From: ( | {
         'ModuleInfo: Module: web InitialContents: InitializeToExpression: (0)'
         winId <- 0.
        } | )


 '-- window-handle behaviour: the in-VM backend was a proxy and inherited these
    from traits proxy; the plugin handle defines them over winId instead
    (liveness is the handle, copies are dead, equality is identity)'

 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'web' -> 'platformWindow' -> () From: ( | {
         'ModuleInfo: Module: web InitialContents: FollowSlot'
         isLive = ( | | winId > 0).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'web' -> 'platformWindow' -> () From: ( | {
         'ModuleInfo: Module: web InitialContents: FollowSlot'
         deadCopy = ( | c |
            c: copy. c winId: 0. c).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'web' -> 'platformWindow' -> () From: ( | {
         'ModuleInfo: Module: web InitialContents: FollowSlot'
         = x = ( | | _Eq: x).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'web' -> 'platformWindow' -> () From: ( | {
         'ModuleInfo: Module: web InitialContents: FollowSlot'
         hash = ( | | _IdentityHash).
        } | )


 '-- CONTEXT protocol (gc): map morphic gc calls to the raw opcode prims'

 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'web' -> 'platformWindow' -> () From: ( | {
         'Category: gc\x7fModuleInfo: Module: web InitialContents: FollowSlot\x7fVisibility: public'
         foreground: aPaint = ( |
            |
            "dedup-aware: skip the prim call when value unchanged (see webCanvas state cache)"
            ensureColorR: (aPaint red   * 255) asInteger
                       G: (aPaint green * 255) asInteger
                       B: (aPaint blue  * 255) asInteger.
            ensureAlpha:  (aPaint alpha * 255) asInteger.
            self).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'web' -> 'platformWindow' -> () From: ( | {
         'Category: gc\x7fModuleInfo: Module: web InitialContents: FollowSlot\x7fVisibility: public'
         font: aWebFontIDAndStruct = ( |
            |
            "dedup-aware: skip the prim call when value unchanged"
            ensureFontPx: aWebFontIDAndStruct fontSize
                    Bold: aWebFontIDAndStruct bold
                  Italic: aWebFontIDAndStruct italic
                  Family: aWebFontIDAndStruct cssFamily.
            self).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'web' -> 'platformWindow' -> () From: ( | {
         'Category: culling\x7fComment: The opcode protocol carries 16-bit coordinates, and the canvas can hand us device coordinates well outside that range for content that is wholly off-screen (e.g. a morph parked at minSmallInt before the hand repositions it). Such a coordinate is a bigInt -> the int draw prims raise "doesn\'t fit into small integer", or a large smallInt -> the i16 cast wraps to garbage. Rather than CLAMP individual coordinates (which would distort partially-off-screen shapes), each draw operation tests whether it is beyond drawable range and skips itself entirely; on-screen and partially-on-screen geometry (always far inside i16, since panning keeps the visible offset small) is drawn untouched. Comparisons are bigInt-safe (no asSmallInteger/abs).\x7fModuleInfo: Module: web InitialContents: FollowSlot\x7fVisibility: private'
         beyondI16: n = ( | | (n > 32000) || [n < (0 - 32000)]).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'web' -> 'platformWindow' -> () From: ( | {
         'Category: culling\x7fModuleInfo: Module: web InitialContents: FollowSlot\x7fVisibility: private'
         rectBeyondI16: r = ( |
            | (beyondI16: r left) || [beyondI16: r top] || [beyondI16: r width] || [beyondI16: r height]).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'web' -> 'platformWindow' -> () From: ( | {
         'Category: culling\x7fModuleInfo: Module: web InitialContents: FollowSlot\x7fVisibility: private'
         ptBeyondI16: p = ( |
            | (beyondI16: p x) || [beyondI16: p y]).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'web' -> 'platformWindow' -> () From: ( | {
         'Category: culling\x7fModuleInfo: Module: web InitialContents: FollowSlot\x7fVisibility: private'
         listBeyondI16: aList = ( |
            | aList do: [| :n | (beyondI16: n) ifTrue: [ ^true ] ]. false).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'web' -> 'platformWindow' -> () From: ( | {
         'Category: culling\x7fModuleInfo: Module: web InitialContents: FollowSlot\x7fVisibility: private'
         ptListBeyondI16: aList = ( |
            | aList do: [| :p | (ptBeyondI16: p) ifTrue: [ ^true ] ]. false).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'web' -> 'platformWindow' -> () From: ( | {
         'Category: gc\x7fModuleInfo: Module: web InitialContents: FollowSlot\x7fVisibility: public'
         fillRectangle: r = ( |
            | (rectBeyondI16: r) ifTrue: [ ^self ].
              fillRectX: r left Y: r top Width: r width Height: r height. self).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'web' -> 'platformWindow' -> () From: ( | {
         'Category: gc\x7fModuleInfo: Module: web InitialContents: FollowSlot\x7fVisibility: public'
         drawRectangle: r = ( |
            | (rectBeyondI16: r) ifTrue: [ ^self ].
              strokeRectX: r left Y: r top Width: r width Height: r height. self).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'web' -> 'platformWindow' -> () From: ( | {
         'Category: gc\x7fComment: inset the rect by half the border width (mirrors quartz) so wide rectangle strokes are consistent; used by the inherited drawRectangle:Width:GC:\x7fModuleInfo: Module: web InitialContents: FollowSlot\x7fVisibility: public'
         adjustRectangle: r Width: borderWidth = ( |
            | (r origin + (borderWidth /+ 2)) # (r corner + (1 max: borderWidth /- 2))).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'web' -> 'platformWindow' -> () From: ( | {
         'Category: gc\x7fModuleInfo: Module: web InitialContents: FollowSlot\x7fVisibility: public'
         drawString: str At: pt = ( |
            | (ptBeyondI16: pt) ifTrue: [ ^self ].
              drawString: str X: pt x Y: pt y. self).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'web' -> 'platformWindow' -> () From: ( | {
         'Category: gc\x7fModuleInfo: Module: web InitialContents: FollowSlot\x7fVisibility: public'
         moveTo: p = ( | | moveToX: p x Y: p y).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'web' -> 'platformWindow' -> () From: ( | {
         'Category: gc\x7fModuleInfo: Module: web InitialContents: FollowSlot\x7fVisibility: public'
         addLineTo: p = ( | | lineToX: p x Y: p y).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'web' -> 'platformWindow' -> () From: ( | {
         'Category: gc\x7fModuleInfo: Module: web InitialContents: FollowSlot\x7fVisibility: public'
         strokePath = ( | | stroke. self).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'web' -> 'platformWindow' -> () From: ( | {
         'Category: gc\x7fModuleInfo: Module: web InitialContents: FollowSlot\x7fVisibility: public'
         fillPath = ( | | fill. self).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'web' -> 'platformWindow' -> () From: ( | {
         'Category: gc\x7fModuleInfo: Module: web InitialContents: FollowSlot\x7fVisibility: public'
         lineWidth: w = ( | | setLineWidth: (w max: 1). self).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'web' -> 'platformWindow' -> () From: ( | {
         'Category: gc\x7fModuleInfo: Module: web InitialContents: FollowSlot\x7fVisibility: public'
         fillEllipseIn: r = ( |
            | (rectBeyondI16: r) ifTrue: [ ^self ].
              arcX: r left Y: r top Width: r width Height: r height Start: 0 Span: 23040 Fill: true. self).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'web' -> 'platformWindow' -> () From: ( | {
         'Category: gc\x7fModuleInfo: Module: web InitialContents: FollowSlot\x7fVisibility: public'
         strokeEllipseX: x Y: y Width: w Height: h = ( |
            | ((beyondI16: x) || [beyondI16: y] || [beyondI16: w] || [beyondI16: h]) ifTrue: [ ^self ].
              arcX: x Y: y Width: w Height: h Start: 0 Span: 23040 Fill: false. self).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'web' -> 'platformWindow' -> () From: ( | {
         'Category: gc\x7fModuleInfo: Module: web InitialContents: FollowSlot\x7fVisibility: public'
         setClipRectangle: r = ( |
            | r ifNil: [ ^ self ]. setClipX: r left Y: r top Width: r width Height: r height. self).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'web' -> 'platformWindow' -> () From: ( | {
         'Category: gc\x7fModuleInfo: Module: web InitialContents: FollowSlot\x7fVisibility: public'
         setNoClipMask = ( | | clearClip. self).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'web' -> 'platformWindow' -> () From: ( | {
         'Category: gc\x7fComment: bitmap clip masks are not supported yet; ignore (image draws unmasked)\x7fModuleInfo: Module: web InitialContents: FollowSlot\x7fVisibility: public'
         setClipMask: maskCanvas Origin: o = ( | | self).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'web' -> 'platformWindow' -> () From: ( | {
         'Category: display\x7fComment: present the accumulated frame to the browser\x7fModuleInfo: Module: web InitialContents: FollowSlot\x7fVisibility: public'
         flush = ( | | endDraw. self).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'web' -> 'platformWindow' -> () From: ( | {
         'Category: display\x7fModuleInfo: Module: web InitialContents: FollowSlot\x7fVisibility: public'
         syncDiscardingIf: b = ( | | endDraw. self).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'web' -> 'platformWindow' -> () From: ( | {
         'Category: display\x7fModuleInfo: Module: web InitialContents: FollowSlot\x7fVisibility: public'
         name = ( | | 'web').
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'web' -> 'platformWindow' -> () From: ( | {
         'Category: cursorOps\x7fComment: a browser cannot reposition the OS pointer; ignore\x7fModuleInfo: Module: web InitialContents: FollowSlot\x7fVisibility: public'
         warpPointerTo: pt = ( | | self).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'web' -> 'platformWindow' -> () From: ( | {
         'Category: cursorOps\x7fComment: the browser manages pointer capture implicitly during a button press; no grab to release\x7fModuleInfo: Module: web InitialContents: FollowSlot\x7fVisibility: public'
         ungrabPointer = ( | | self).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'web' -> 'platformWindow' -> () From: ( | {
         'Category: cursorOps\x7fComment: cursor shape is cosmetic on web; revert to the default cursor is a no-op\x7fModuleInfo: Module: web InitialContents: FollowSlot\x7fVisibility: public'
         undefineCursor = ( | | self).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'web' -> 'platformWindow' -> () From: ( | {
         'Category: window management\x7fComment: single browser window; nothing to raise\x7fModuleInfo: Module: web InitialContents: FollowSlot\x7fVisibility: public'
         raise = ( | | self).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'web' -> 'platformWindow' -> () From: ( | {
         'Category: window management\x7fComment: window-close arrives as a close event (isDeleteWindow); no WM protocol to register\x7fModuleInfo: Module: web InitialContents: FollowSlot\x7fVisibility: public'
         catchWMDelete = ( | | self).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'web' -> 'platformWindow' -> () From: ( | {
         'Category: gc\x7fComment: stipple/tile fill styles unsupported; draw solid\x7fModuleInfo: Module: web InitialContents: FollowSlot\x7fVisibility: public'
         fillStippled = ( | | self).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'web' -> 'platformWindow' -> () From: ( | {
         'Category: gc\x7fModuleInfo: Module: web InitialContents: FollowSlot\x7fVisibility: public'
         fillSolid = ( | | self).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'web' -> 'platformWindow' -> () From: ( | {
         'Category: gc\x7fModuleInfo: Module: web InitialContents: FollowSlot\x7fVisibility: public'
         fillStyle: s = ( | | self).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'web' -> 'platformWindow' -> () From: ( | {
         'Category: gc\x7fModuleInfo: Module: web InitialContents: FollowSlot\x7fVisibility: public'
         withClip: newClip Do: blk = ( |
            |
            newClip ifNil: [ ^ blk value ].
            setClipX: newClip left Y: newClip top Width: newClip width Height: newClip height.
            blk value.
            clearClip.
            self).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'web' -> 'platformWindow' -> () From: ( | {
         'Category: gc\x7fModuleInfo: Module: web InitialContents: FollowSlot\x7fVisibility: public'
         drawPolygonIntegerXs: xs Ys: ys = ( |
            |
            ((listBeyondI16: xs) || [listBeyondI16: ys]) ifTrue: [ ^self ].
            beginPath.
            xs with: ys Do: [|:x. :y. :i|
              i = 0 ifTrue: [moveToX: x Y: y] False: [lineToX: x Y: y]].
            closePath. stroke. self).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'web' -> 'platformWindow' -> () From: ( | {
         'Category: gc\x7fModuleInfo: Module: web InitialContents: FollowSlot\x7fVisibility: public'
         fillPolygonIntegerXs: xs Ys: ys = ( |
            |
            ((listBeyondI16: xs) || [listBeyondI16: ys]) ifTrue: [ ^self ].
            beginPath.
            xs with: ys Do: [|:x. :y. :i|
              i = 0 ifTrue: [moveToX: x Y: y] False: [lineToX: x Y: y]].
            closePath. fill. self).
        } | )


 '-- DRAWABLE protocol: morphic calls these on the canvas drawable, passing GC'

 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'web' -> 'platformWindow' -> () From: ( | {
         'Category: drawable\x7fModuleInfo: Module: web InitialContents: FollowSlot\x7fVisibility: public'
         fillRectangle: r GC: gc = ( | | gc fillRectangle: r. self).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'web' -> 'platformWindow' -> () From: ( | {
         'Category: drawable\x7fModuleInfo: Module: web InitialContents: FollowSlot\x7fVisibility: public'
         drawRectangle: r GC: gc = ( | | gc drawRectangle: r. self).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'web' -> 'platformWindow' -> () From: ( | {
         'Category: drawable\x7fModuleInfo: Module: web InitialContents: FollowSlot\x7fVisibility: public'
         drawLine: pt1 To: pt2 GC: gc = ( |
            | ((ptBeyondI16: pt1) || [ptBeyondI16: pt2]) ifTrue: [ ^self ].
              gc drawLineX1: pt1 x Y1: pt1 y X2: pt2 x Y2: pt2 y. self).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'web' -> 'platformWindow' -> () From: ( | {
         'Category: drawable\x7fModuleInfo: Module: web InitialContents: FollowSlot\x7fVisibility: public'
         drawLines: ptlist GC: gc = ( |
            |
            (ptListBeyondI16: ptlist) ifTrue: [ ^self ].
            gc beginPath.
            ptlist doFirst: [|:p| gc moveTo: p] MiddleLast: [|:p| gc addLineTo: p].
            gc stroke. self).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'web' -> 'platformWindow' -> () From: ( | {
         'Category: drawable\x7fModuleInfo: Module: web InitialContents: FollowSlot\x7fVisibility: public'
         drawString: str At: pt GC: gc = ( | | gc drawString: str At: pt. self).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'web' -> 'platformWindow' -> () From: ( | {
         'Category: drawable\x7fModuleInfo: Module: web InitialContents: FollowSlot\x7fVisibility: public'
         drawPoint: p GC: gc = ( | | (ptBeyondI16: p) ifTrue: [ ^self ]. gc drawPointX: p x Y: p y. self).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'web' -> 'platformWindow' -> () From: ( | {
         'Category: drawable\x7fModuleInfo: Module: web InitialContents: FollowSlot\x7fVisibility: public'
         drawArcWithin: r From: startAngle Spanning: spanAngle GC: gc = ( |
            | (rectBeyondI16: r) ifTrue: [ ^self ].
              gc arcX: r origin x Y: r origin y Width: r width Height: r height
                 Start: startAngle * 64 Span: spanAngle * 64 Fill: false. self).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'web' -> 'platformWindow' -> () From: ( | {
         'Category: drawable\x7fModuleInfo: Module: web InitialContents: FollowSlot\x7fVisibility: public'
         fillArcWithin: r From: startAngle Spanning: spanAngle GC: gc = ( |
            | (rectBeyondI16: r) ifTrue: [ ^self ].
              gc arcX: r origin x Y: r origin y Width: r width Height: r height
                 Start: startAngle * 64 Span: spanAngle * 64 Fill: true. self).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'web' -> 'platformWindow' -> () From: ( | {
         'Category: drawable\x7fModuleInfo: Module: web InitialContents: FollowSlot\x7fVisibility: public'
         drawPolygonIntegerXs: xs Ys: ys GC: gc = ( | | gc drawPolygonIntegerXs: xs Ys: ys. self).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'web' -> 'platformWindow' -> () From: ( | {
         'Category: drawable\x7fModuleInfo: Module: web InitialContents: FollowSlot\x7fVisibility: public'
         fillPolygonIntegerXs: xs Ys: ys GC: gc = ( | | gc fillPolygonIntegerXs: xs Ys: ys. self).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'web' -> 'platformWindow' -> () From: ( | {
         'Category: drawable\x7fModuleInfo: Module: web InitialContents: FollowSlot\x7fVisibility: public'
         withClip: newClip Do: blk GC: gc = ( | | gc withClip: newClip Do: blk. self).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'web' -> 'platformWindow' -> () From: ( | {
         'Category: drawable\x7fModuleInfo: Module: web InitialContents: FollowSlot\x7fVisibility: public'
         withClip: newClip Do: blk = ( | | withClip: newClip Do: blk. self).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'web' -> 'platformWindow' -> () From: ( | {
         'Category: drawable\x7fModuleInfo: Module: web InitialContents: FollowSlot\x7fVisibility: public'
         withAntialiasing: bool Do: blk = ( | | blk value. self).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'web' -> 'platformWindow' -> () From: ( | {
         'Category: drawable\x7fModuleInfo: Module: web InitialContents: FollowSlot\x7fVisibility: public'
         translucentlyDo: blk = ( | | ensureAlpha: 128. blk value. ensureAlpha: 255. self).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'web' -> 'platformWindow' -> () From: ( | {
         'Category: drawable\x7fModuleInfo: Module: web InitialContents: FollowSlot\x7fVisibility: public'
         copyArea: rect To: dstDrawable At: pt GC: srcGC = ( |
            |
            "Pixmap/window blits go through webWindowCanvas pastePixmap: (which emits
             copyAreaSrc: with the source pixmap id, since here every drawable is the
             one platformWindow).  This generic entry is only reached by copyPixmapAt:
             (window->pixmap readback), which the web backend can't do, so: no-op."
            self).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'web' -> 'platformWindow' -> () From: ( | {
         'Category: drawable\x7fModuleInfo: Module: web InitialContents: FollowSlot\x7fVisibility: public'
         depth = ( | | 32).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'web' -> 'platformWindow' -> () From: ( | {
         'Category: drawable\x7fModuleInfo: Module: web InitialContents: FollowSlot\x7fVisibility: public'
         size = ( | | width @ height).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'web' -> 'platformWindow' -> () From: ( | {
         'Category: drawable\x7fModuleInfo: Module: web InitialContents: FollowSlot\x7fVisibility: public'
         screen = ( | | self).
        } | )


 '-- Side effects'

 globals modules web postFileIn
