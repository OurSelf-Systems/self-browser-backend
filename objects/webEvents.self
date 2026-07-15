 '$Revision: 30.1 $'
 '
Copyright 2026 AUTHORS.
See the LICENSE file for license information.
'

 "Web raw input event.  webCanvas nextEvent returns one of these; it 'quacks
  like' an X event so we can reuse x11Globals ui2Event's setFrom* machinery
  (double dispatch: ui2Event setFrom: rawEvt -> rawEvt setUI2Event: ui2Event ->
  ui2Event setFromButtonPress: rawEvt ...).  Fields are read from the C++
  WebWindow via the generated event accessor prims (eventX, eventButton, ...)."

 '-- Module body'

 bootstrap addSlotsTo: bootstrap stub -> 'globals' -> 'modules' -> () From: ( | {
         'ModuleInfo: Module: webEvents InitialContents: FollowSlot'
         webEvents = bootstrap define: bootstrap stub -> 'globals' -> 'modules' -> 'webEvents' -> () ToBe: bootstrap addSlotsTo: (
             bootstrap remove: 'directory' From:
             bootstrap remove: 'fileInTimeString' From:
             bootstrap remove: 'myComment' From:
             bootstrap remove: 'postFileIn' From:
             bootstrap remove: 'revision' From:
             bootstrap remove: 'subpartNames' From:
             globals modules init copy ) From: bootstrap setObjectAnnotationOf: bootstrap stub -> 'globals' -> 'modules' -> 'webEvents' -> () From: ( |
             {} = 'ModuleInfo: Creator: globals modules webEvents.

CopyDowns:
globals modules init. copy
SlotsToOmit: directory fileInTimeString myComment postFileIn revision subpartNames.

\x7fIsComplete: '.
            | ) .
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'globals' -> 'modules' -> 'webEvents' -> () From: ( | {
         'ModuleInfo: Module: webEvents InitialContents: FollowSlot\x7fVisibility: public'
         directory <- '../../self-browser-backend/objects'.
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'globals' -> 'modules' -> 'webEvents' -> () From: ( | {
         'ModuleInfo: Module: webEvents InitialContents: InitializeToExpression: (_CurrentTimeString)\x7fVisibility: public'
         fileInTimeString <- _CurrentTimeString.
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'globals' -> 'modules' -> 'webEvents' -> () From: ( | {
         'ModuleInfo: Module: webEvents InitialContents: FollowSlot'
         myComment <- ''.
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'globals' -> 'modules' -> 'webEvents' -> () From: ( | {
         'ModuleInfo: Module: webEvents InitialContents: FollowSlot'
         postFileIn = ( | | resend.postFileIn).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'globals' -> 'modules' -> 'webEvents' -> () From: ( | {
         'ModuleInfo: Module: webEvents InitialContents: FollowSlot\x7fVisibility: public'
         revision <- '$Revision: 30.1 $'.
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'globals' -> 'modules' -> 'webEvents' -> () From: ( | {
         'ModuleInfo: Module: webEvents InitialContents: FollowSlot\x7fVisibility: private'
         subpartNames <- ''.
        } | )

 '-- webGlobals webRawEvent'

 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> () From: ( | {
         'Category: graphical interface\x7fModuleInfo: Module: webEvents InitialContents: FollowSlot\x7fVisibility: public'
         webRawEvent = bootstrap setObjectAnnotationOf: bootstrap stub -> 'traits' -> 'webRawEvent' -> () From: ( |
             {} = 'ModuleInfo: Creator: traits webRawEvent.
'.
            | ) .
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webRawEvent' -> () From: ( | {
         'ModuleInfo: Module: webEvents InitialContents: FollowSlot'
         parent* = bootstrap stub -> 'traits' -> 'clonable' -> ().
        } | )

 bootstrap addSlotsTo: bootstrap stub -> 'globals' -> 'webGlobals' -> () From: ( | {
         'Category: graphical interface\x7fModuleInfo: Module: webEvents InitialContents: FollowSlot\x7fVisibility: public'
         webRawEvent = bootstrap setObjectAnnotationOf: bootstrap stub -> 'globals' -> 'webGlobals' -> 'webRawEvent' -> () From: ( |
             {} = 'ModuleInfo: Creator: globals webGlobals webRawEvent.
'.
            | ) .
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'globals' -> 'webGlobals' -> 'webRawEvent' -> () From: ( | {
         'ModuleInfo: Module: webEvents InitialContents: FollowSlot'
         parent* = bootstrap stub -> 'traits' -> 'webRawEvent' -> ().
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'globals' -> 'webGlobals' -> 'webRawEvent' -> () From: ( | {
         'ModuleInfo: Module: webEvents InitialContents: FollowSlot\x7fVisibility: private'
         evType <- 0. evX <- 0. evY <- 0. evButton <- 0. evState <- 0.
         evKeysym <- 0. evChar <- 0. evW <- 0. evH <- 0.
        } | )

 '-- construction'

 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webRawEvent' -> () From: ( | {
         'Category: construction\x7fModuleInfo: Module: webEvents InitialContents: FollowSlot\x7fVisibility: public'
         copyFromWindow: pw Popping: pop = ( |
             c.
            |
            c: copy.
            pop ifTrue: [ c evType: pw nextEventType ] False: [ c evType: 0 ].
            c evX: pw eventX.  c evY: pw eventY.
            c evButton: pw eventButton.  c evState: pw eventState.
            c evKeysym: pw eventKeysym.  c evChar: pw eventChar.
            c evW: pw eventW.  c evH: pw eventH.
            "map scroll (6) to an X wheel button press (4 up / 5 down)"
            c evType = 6 ifTrue: [ c evButton: (c evH < 0 ifTrue: 4 False: 5). c evType: 1 ].
            c).
        } | )

 '-- X-event quacking: double-dispatch + accessors the x11 setFrom* read'

 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webRawEvent' -> () From: ( | {
         'Category: dispatch\x7fModuleInfo: Module: webEvents InitialContents: FollowSlot\x7fVisibility: public'
         setUI2Event: e = ( |
            |
            case
              if:  [ evType = 1 ] Then: [ e setFromButtonPress: self ]
              If:  [ evType = 2 ] Then: [ e setFromButtonRelease: self ]
              If:  [ evType = 3 ] Then: [ e setFromMotionNotify: self ]
              If:  [ evType = 4 ] Then: [ e setFromKeyPress: self ]
              If:  [ evType = 5 ] Then: [ e setFromKeyRelease: self ]
              If:  [ evType = 7 ] Then: [ webGlobals invalidateStateCache.   "the JS client's setDrawableState resets the resized canvas2D state -- drop our stale cache so the next frame re-emits everything (covers reconnect resync + user-driven viewport resize)" e setFromConfigure: self ]
              If:  [ evType = 8 ] Then: [ e setFromWindowDelete ]
              Else: [ e ].
            self).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webRawEvent' -> () From: ( | {
         'Category: accessors\x7fModuleInfo: Module: webEvents InitialContents: FollowSlot\x7fVisibility: public'
         button = ( | | evButton).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webRawEvent' -> () From: ( | {
         'Category: accessors\x7fModuleInfo: Module: webEvents InitialContents: FollowSlot\x7fVisibility: public'
         x = ( | | evX).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webRawEvent' -> () From: ( | {
         'Category: accessors\x7fModuleInfo: Module: webEvents InitialContents: FollowSlot\x7fVisibility: public'
         y = ( | | evY).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webRawEvent' -> () From: ( | {
         'Category: accessors\x7fModuleInfo: Module: webEvents InitialContents: FollowSlot\x7fVisibility: public'
         width = ( | | evW).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webRawEvent' -> () From: ( | {
         'Category: accessors\x7fModuleInfo: Module: webEvents InitialContents: FollowSlot\x7fVisibility: public'
         height = ( | | evH).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webRawEvent' -> () From: ( | {
         'Category: accessors\x7fModuleInfo: Module: webEvents InitialContents: FollowSlot\x7fVisibility: public'
         time = ( | | times real msec).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webRawEvent' -> () From: ( | {
         'Category: accessors\x7fComment: morphic state is an X modifier mask\x7fModuleInfo: Module: webEvents InitialContents: FollowSlot\x7fVisibility: public'
         state = ( |
             m.
            |
            m: 0.
            (evState && 1) > 0 ifTrue: [ m: m || 1 ].   "shift -> ShiftMask"
            (evState && 2) > 0 ifTrue: [ m: m || 4 ].   "ctrl  -> ControlMask"
            (evState && 4) > 0 ifTrue: [ m: m || 8 ].   "alt   -> Mod1Mask"
            m).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webRawEvent' -> () From: ( | {
         'Category: accessors\x7fModuleInfo: Module: webEvents InitialContents: FollowSlot\x7fVisibility: public'
         keycode = ( | | evKeysym).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webRawEvent' -> () From: ( | {
         'Category: accessors\x7fModuleInfo: Module: webEvents InitialContents: FollowSlot\x7fVisibility: public'
         lookupKeySym = ( | | evKeysym).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webRawEvent' -> () From: ( | {
         'Category: accessors\x7fModuleInfo: Module: webEvents InitialContents: FollowSlot\x7fVisibility: public'
         lookupString = ( | | evChar = 0 ifTrue: [ '' ] False: [ '' copyAddLast: evChar asCharacter ]).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webRawEvent' -> () From: ( | {
         'Category: queries\x7fModuleInfo: Module: webEvents InitialContents: FollowSlot\x7fVisibility: public'
         isMotionEvent = ( | | evType = 3).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webRawEvent' -> () From: ( | {
         'Category: queries\x7fModuleInfo: Module: webEvents InitialContents: FollowSlot\x7fVisibility: public'
         isDeleteWindow = ( | | evType = 8).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webRawEvent' -> () From: ( | {
         'Category: lifecycle\x7fModuleInfo: Module: webEvents InitialContents: FollowSlot\x7fVisibility: public'
         delete = ( | | self).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webRawEvent' -> () From: ( | {
         'Category: keysym constants (X keysyms for arrows, used by keySymFrom:)\x7fModuleInfo: Module: webEvents InitialContents: FollowSlot\x7fVisibility: public'
         xk_Left     = ( | | 16rFF51).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webRawEvent' -> () From: ( | {
         'ModuleInfo: Module: webEvents InitialContents: FollowSlot\x7fVisibility: public'
         xk_Up       = ( | | 16rFF52).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webRawEvent' -> () From: ( | {
         'ModuleInfo: Module: webEvents InitialContents: FollowSlot\x7fVisibility: public'
         xk_Right    = ( | | 16rFF53).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webRawEvent' -> () From: ( | {
         'ModuleInfo: Module: webEvents InitialContents: FollowSlot\x7fVisibility: public'
         xk_Down     = ( | | 16rFF54).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webRawEvent' -> () From: ( | {
         'ModuleInfo: Module: webEvents InitialContents: FollowSlot\x7fVisibility: public'
         xk_KP_Left  = ( | | 16rFF96).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webRawEvent' -> () From: ( | {
         'ModuleInfo: Module: webEvents InitialContents: FollowSlot\x7fVisibility: public'
         xk_KP_Up    = ( | | 16rFF97).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webRawEvent' -> () From: ( | {
         'ModuleInfo: Module: webEvents InitialContents: FollowSlot\x7fVisibility: public'
         xk_KP_Right = ( | | 16rFF98).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webRawEvent' -> () From: ( | {
         'ModuleInfo: Module: webEvents InitialContents: FollowSlot\x7fVisibility: public'
         xk_KP_Down  = ( | | 16rFF99).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webRawEvent' -> () From: ( | {
         'Comment: X11 modifier keysyms keySymFrom: tests against\x7fModuleInfo: Module: webEvents InitialContents: FollowSlot\x7fVisibility: public'
         xk_Shift_L   = ( | | 16rFFE1).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webRawEvent' -> () From: ( | {
         'ModuleInfo: Module: webEvents InitialContents: FollowSlot\x7fVisibility: public'
         xk_Shift_R   = ( | | 16rFFE2).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webRawEvent' -> () From: ( | {
         'ModuleInfo: Module: webEvents InitialContents: FollowSlot\x7fVisibility: public'
         xk_Control_L = ( | | 16rFFE3).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webRawEvent' -> () From: ( | {
         'ModuleInfo: Module: webEvents InitialContents: FollowSlot\x7fVisibility: public'
         xk_Control_R = ( | | 16rFFE4).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webRawEvent' -> () From: ( | {
         'ModuleInfo: Module: webEvents InitialContents: FollowSlot\x7fVisibility: public'
         xk_Alt_L     = ( | | 16rFFE9).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webRawEvent' -> () From: ( | {
         'ModuleInfo: Module: webEvents InitialContents: FollowSlot\x7fVisibility: public'
         xk_Alt_R     = ( | | 16rFFEA).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webRawEvent' -> () From: ( | {
         'ModuleInfo: Module: webEvents InitialContents: FollowSlot\x7fVisibility: public'
         xk_Super_L   = ( | | 16rFFEB).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webRawEvent' -> () From: ( | {
         'ModuleInfo: Module: webEvents InitialContents: FollowSlot\x7fVisibility: public'
         xk_Super_R   = ( | | 16rFFEC).
        } | )

 '-- Side effects'

 globals modules webEvents postFileIn
