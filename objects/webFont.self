 '$Revision: 30.1 $'
 '
Copyright 2026 AUTHORS.
See the LICENSE file for license information.
'

 "Minimal font support for the web backend.  webGlobals fontDictionary maps a
  fontSpec to a webFont, which carries the CSS family + pixel size the gc needs
  (font: -> setFontPx:Family:) and answers text metrics with a fixed advance
  estimate (refined later via canvas measureText)."

 '-- Module body'

 bootstrap addSlotsTo: bootstrap stub -> 'globals' -> 'modules' -> () From: ( | {
         'ModuleInfo: Module: webFont InitialContents: FollowSlot'
         webFont = bootstrap define: bootstrap stub -> 'globals' -> 'modules' -> 'webFont' -> () ToBe: bootstrap addSlotsTo: (
             bootstrap remove: 'directory' From:
             bootstrap remove: 'fileInTimeString' From:
             bootstrap remove: 'myComment' From:
             bootstrap remove: 'postFileIn' From:
             bootstrap remove: 'revision' From:
             bootstrap remove: 'subpartNames' From:
             globals modules init copy ) From: bootstrap setObjectAnnotationOf: bootstrap stub -> 'globals' -> 'modules' -> 'webFont' -> () From: ( |
             {} = 'ModuleInfo: Creator: globals modules webFont.

CopyDowns:
globals modules init. copy
SlotsToOmit: directory fileInTimeString myComment postFileIn revision subpartNames.

\x7fIsComplete: '.
            | ) .
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'globals' -> 'modules' -> 'webFont' -> () From: ( | {
         'ModuleInfo: Module: webFont InitialContents: FollowSlot\x7fVisibility: public'
         directory <- '../../web-backend-plugin/objects'.
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'globals' -> 'modules' -> 'webFont' -> () From: ( | {
         'ModuleInfo: Module: webFont InitialContents: InitializeToExpression: (_CurrentTimeString)\x7fVisibility: public'
         fileInTimeString <- _CurrentTimeString.
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'globals' -> 'modules' -> 'webFont' -> () From: ( | {
         'ModuleInfo: Module: webFont InitialContents: FollowSlot'
         myComment <- ''.
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'globals' -> 'modules' -> 'webFont' -> () From: ( | {
         'ModuleInfo: Module: webFont InitialContents: FollowSlot'
         postFileIn = ( | | resend.postFileIn).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'globals' -> 'modules' -> 'webFont' -> () From: ( | {
         'ModuleInfo: Module: webFont InitialContents: FollowSlot\x7fVisibility: public'
         revision <- '$Revision: 30.1 $'.
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'globals' -> 'modules' -> 'webFont' -> () From: ( | {
         'ModuleInfo: Module: webFont InitialContents: FollowSlot\x7fVisibility: private'
         subpartNames <- ''.
        } | )

 '-- The webFont prototype (a font ID + struct)'

 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> () From: ( | {
         'Category: graphical interface\x7fModuleInfo: Module: webFont InitialContents: FollowSlot\x7fVisibility: public'
         webFont = bootstrap setObjectAnnotationOf: bootstrap stub -> 'traits' -> 'webFont' -> () From: ( |
             {} = 'ModuleInfo: Creator: traits webFont.
'.
            | ) .
        } | )

 bootstrap addSlotsTo: bootstrap stub -> 'globals' -> 'webGlobals' -> () From: ( | {
         'Category: graphical interface\x7fModuleInfo: Module: webFont InitialContents: FollowSlot\x7fVisibility: public'
         webFont = bootstrap setObjectAnnotationOf: bootstrap stub -> 'globals' -> 'webGlobals' -> 'webFont' -> () From: ( |
             {} = 'ModuleInfo: Creator: globals webGlobals webFont.
'.
            | ) .
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'globals' -> 'webGlobals' -> 'webFont' -> () From: ( | {
         'ModuleInfo: Module: webFont InitialContents: FollowSlot'
         parent* = bootstrap stub -> 'traits' -> 'webFont' -> ().
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'globals' -> 'webGlobals' -> 'webFont' -> () From: ( | {
         'ModuleInfo: Module: webFont InitialContents: InitializeToExpression: (13)\x7fVisibility: public'
         fontSize <- 13.
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'globals' -> 'webGlobals' -> 'webFont' -> () From: ( | {
         'ModuleInfo: Module: webFont InitialContents: InitializeToExpression: (\'sans-serif\')\x7fVisibility: public'
         cssFamily <- 'sans-serif'.
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'globals' -> 'webGlobals' -> 'webFont' -> () From: ( | {
         'ModuleInfo: Module: webFont InitialContents: InitializeToExpression: (false)\x7fVisibility: public'
         bold <- bootstrap stub -> 'globals' -> 'false' -> ().
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'globals' -> 'webGlobals' -> 'webFont' -> () From: ( | {
         'ModuleInfo: Module: webFont InitialContents: InitializeToExpression: (false)\x7fVisibility: public'
         italic <- bootstrap stub -> 'globals' -> 'false' -> ().
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'globals' -> 'webGlobals' -> 'webFont' -> () From: ( | {
         'ModuleInfo: Module: webFont InitialContents: InitializeToExpression: (0)\x7fVisibility: public'
         fontId <- 0.
        } | )

 '-- webGlobals: map Self family/style to a CSS font + assign a small font id per
     (family,bold,italic) so the browser can measure each distinct font once.'

 bootstrap addSlotsTo: bootstrap stub -> 'globals' -> 'webGlobals' -> () From: ( | {
         'Category: graphical interface\x7fModuleInfo: Module: webFont InitialContents: InitializeToExpression: (1)\x7fVisibility: private'
         nextFontId <- 1.
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'globals' -> 'webGlobals' -> () From: ( | {
         'Category: graphical interface\x7fModuleInfo: Module: webFont InitialContents: InitializeToExpression: (dictionary copyRemoveAll)\x7fVisibility: private'
         fontIdMap <- dictionary copyRemoveAll.
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'globals' -> 'webGlobals' -> () From: ( | {
         'Category: graphical interface\x7fComment: a generic CSS fallback family by heuristic on the (lowercased) name\x7fModuleInfo: Module: webFont InitialContents: FollowSlot\x7fVisibility: public'
         genericFallbackFor: nm = ( |
            |
            nm isEmpty ifTrue: [ ^'sans-serif' ].
            "X11 bitmap fixed fonts ('6x13', '9x15', '10x20') are monospace"
            ((nm first isDigit) && [nm includesSubstring: 'x']) ifTrue: [ ^'monospace' ].
            ((nm includesSubstring: 'mono') || [nm includesSubstring: 'courier'] || [nm includesSubstring: 'fixed'] || [nm includesSubstring: 'menlo'] || [nm includesSubstring: 'consol']) ifTrue: [ ^'monospace' ].
            (nm includesSubstring: 'sans') ifTrue: [ ^'sans-serif' ].
            ((nm includesSubstring: 'serif') || [nm includesSubstring: 'times'] || [nm includesSubstring: 'georgia']) ifTrue: [ ^'serif' ].
            'sans-serif').
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'globals' -> 'webGlobals' -> () From: ( | {
         'Category: graphical interface\x7fComment: a CSS font-family list "<name>, <generic>" so any family works with a safe fallback\x7fModuleInfo: Module: webFont InitialContents: FollowSlot\x7fVisibility: public'
         cssFamilyFor: nm = ( |
            |
            nm isEmpty ifTrue: [ ^'sans-serif' ].
            "quote the specific family: X11 names like '6x13' start with a digit and
             are invalid unquoted CSS identifiers, so the browser would reject the
             whole font string and silently fall back to the 10px default"
            '"', nm, '", ', (genericFallbackFor: nm)).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'globals' -> 'webGlobals' -> () From: ( | {
         'Category: graphical interface\x7fComment: small int id per (cssFamily,bold,italic); 0 if the table is full (-> estimate)\x7fModuleInfo: Module: webFont InitialContents: FollowSlot\x7fVisibility: public'
         fontIdFor: css Bold: b Italic: i = ( |
             key.
             id.
            |
            key: css, (b ifTrue: ['/B'] False: ['']), (i ifTrue: ['/I'] False: ['']).
            (fontIdMap includesKey: key) ifTrue: [ ^fontIdMap at: key ].
            id: nextFontId. nextFontId: nextFontId succ.
            id >= 128 ifTrue: [ ^0 ].
            fontIdMap at: key Put: id. id).
        } | )

 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webFont' -> () From: ( | {
         'ModuleInfo: Module: webFont InitialContents: FollowSlot'
         parent* = bootstrap stub -> 'traits' -> 'clonable' -> ().
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webFont' -> () From: ( | {
         'Category: accessing\x7fModuleInfo: Module: webFont InitialContents: FollowSlot\x7fVisibility: public'
         postScriptName = ( | | cssFamily).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webFont' -> () From: ( | {
         'Category: copying\x7fModuleInfo: Module: webFont InitialContents: FollowSlot\x7fVisibility: public'
         copySize: px = ( | c | c: copy. c fontSize: (px max: 1). c).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webFont' -> () From: ( | {
         'Category: copying\x7fModuleInfo: Module: webFont InitialContents: FollowSlot\x7fVisibility: public'
         copyName: nm = ( | c. css | c: copy. css: webGlobals cssFamilyFor: nm. c cssFamily: css. c fontId: (webGlobals fontIdFor: css Bold: bold Italic: italic). web platformWindow registerFont: c fontId Family: css Bold: bold Italic: italic. c).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webFont' -> () From: ( | {
         'Category: metrics\x7fModuleInfo: Module: webFont InitialContents: FollowSlot\x7fVisibility: public'
         ascent = ( | | web platformWindow fontAscentOf: fontId Size: fontSize).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webFont' -> () From: ( | {
         'Category: metrics\x7fModuleInfo: Module: webFont InitialContents: FollowSlot\x7fVisibility: public'
         descent = ( | | web platformWindow fontDescentOf: fontId Size: fontSize).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webFont' -> () From: ( | {
         'Category: metrics\x7fModuleInfo: Module: webFont InitialContents: FollowSlot\x7fVisibility: public'
         height = ( | | ascent + descent).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webFont' -> () From: ( | {
         'Category: metrics\x7fModuleInfo: Module: webFont InitialContents: FollowSlot\x7fVisibility: public'
         maxCharHeight = ( | | height).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webFont' -> () From: ( | {
         'Category: metrics\x7fModuleInfo: Module: webFont InitialContents: FollowSlot\x7fVisibility: public'
         charWidth = ( | | (widthOfString: 'n') max: 1).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webFont' -> () From: ( | {
         'Category: metrics\x7fModuleInfo: Module: webFont InitialContents: FollowSlot\x7fVisibility: public'
         maxCharWidth = ( | | (widthOfString: 'M') max: 1).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webFont' -> () From: ( | {
         'Category: metrics\x7fModuleInfo: Module: webFont InitialContents: FollowSlot\x7fVisibility: public'
         widthOfString: s = ( | | web platformWindow textWidthOfFont: fontId Size: fontSize String: s).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webFont' -> () From: ( | {
         'Category: metrics\x7fModuleInfo: Module: webFont InitialContents: FollowSlot\x7fVisibility: public'
         textWidth: s = ( | | widthOfString: s).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webFont' -> () From: ( | {
         'Category: metrics\x7fModuleInfo: Module: webFont InitialContents: FollowSlot\x7fVisibility: public'
         textWidth: s From: a UpTo: b = ( | | widthOfString: (s copyFrom: a UpTo: b)).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webFont' -> () From: ( | {
         'Category: metrics\x7fModuleInfo: Module: webFont InitialContents: FollowSlot\x7fVisibility: public'
         heightOfString: s = ( | | height).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webFont' -> () From: ( | {
         'Category: metrics\x7fModuleInfo: Module: webFont InitialContents: FollowSlot\x7fVisibility: public'
         sizeOfString: s = ( | | (widthOfString: s) @ (heightOfString: s)).
        } | )

 '-- The font dictionary (fontSpec -> webFont)'

 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> () From: ( | {
         'Category: graphical interface\x7fModuleInfo: Module: webFont InitialContents: FollowSlot\x7fVisibility: public'
         webFontDictionary = bootstrap setObjectAnnotationOf: bootstrap stub -> 'traits' -> 'webFontDictionary' -> () From: ( |
             {} = 'ModuleInfo: Creator: traits webFontDictionary.
'.
            | ) .
        } | )

 bootstrap addSlotsTo: bootstrap stub -> 'globals' -> 'webGlobals' -> () From: ( | {
         'Category: graphical interface\x7fModuleInfo: Module: webFont InitialContents: FollowSlot\x7fVisibility: public'
         fontDictionary = bootstrap setObjectAnnotationOf: bootstrap stub -> 'globals' -> 'webGlobals' -> 'fontDictionary' -> () From: ( |
             {} = 'ModuleInfo: Creator: globals webGlobals fontDictionary.
'.
            | ) .
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'globals' -> 'webGlobals' -> 'fontDictionary' -> () From: ( | {
         'ModuleInfo: Module: webFont InitialContents: FollowSlot'
         parent* = bootstrap stub -> 'traits' -> 'webFontDictionary' -> ().
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webFontDictionary' -> () From: ( | {
         'ModuleInfo: Module: webFont InitialContents: FollowSlot'
         parent* = bootstrap stub -> 'traits' -> 'clonable' -> ().
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webFontDictionary' -> () From: ( | {
         'Category: accessing\x7fModuleInfo: Module: webFont InitialContents: FollowSlot\x7fVisibility: public'
         copyRemoveAll = ( | | copy).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webFontDictionary' -> () From: ( | {
         'Category: accessing\x7fModuleInfo: Module: webFont InitialContents: FollowSlot\x7fVisibility: public'
         idForFontSpec: fSpec WindowCanvas: wc = ( |
             css.
             bold.
             italic.
             f.
            |
            css:    webGlobals cssFamilyFor: fSpec name.
            bold:   fSpec style includesSubstring: 'bold'.
            italic: fSpec style includesSubstring: 'italic'.
            f: webGlobals webFont copy.
            f cssFamily: css.
            f bold: bold.  f italic: italic.
            f fontSize: (fSpec size max: 1).
            f fontId: (webGlobals fontIdFor: css Bold: bold Italic: italic).
            "register so the browser measures this font (once per id, guarded in C++)"
            web platformWindow registerFont: f fontId Family: css Bold: bold Italic: italic.
            f).
        } | )
 bootstrap addSlotsTo: bootstrap stub -> 'traits' -> 'webFontDictionary' -> () From: ( | {
         'Category: accessing\x7fModuleInfo: Module: webFont InitialContents: FollowSlot\x7fVisibility: public'
         structForFontSpec: fSpec WindowCanvas: wc = ( |
            | idForFontSpec: fSpec WindowCanvas: wc).
        } | )

 '-- Side effects'

 globals modules webFont postFileIn
