 '$Revision: 30.1 $'
 '
Copyright 2026 AUTHORS.
See the LICENSE file for license information.
'


 '-- Module body'

 bootstrap addSlotsTo: bootstrap stub -> 'globals' -> 'modules' -> () From: ( | {
         'ModuleInfo: Module: webHosts InitialContents: FollowSlot'

         webHosts = bootstrap define: bootstrap stub -> 'globals' -> 'modules' -> 'webHosts' -> () ToBe: bootstrap addSlotsTo: (
             bootstrap remove: 'directory' From:
             bootstrap remove: 'fileInTimeString' From:
             bootstrap remove: 'myComment' From:
             bootstrap remove: 'postFileIn' From:
             bootstrap remove: 'revision' From:
             bootstrap remove: 'subpartNames' From:
             globals modules init copy ) From: bootstrap setObjectAnnotationOf: bootstrap stub -> 'globals' -> 'modules' -> 'webHosts' -> () From: ( |
             {} = 'ModuleInfo: Creator: globals modules webHosts.

CopyDowns:
globals modules init. copy
SlotsToOmit: directory fileInTimeString myComment postFileIn revision subpartNames.

\x7fIsComplete: '.
            | ) .
        } | )

 bootstrap addSlotsTo: bootstrap stub -> 'globals' -> 'modules' -> 'webHosts' -> () From: ( | {
         'ModuleInfo: Module: webHosts InitialContents: FollowSlot\x7fVisibility: public'

         directory <- '../../web-backend-plugin'.
        } | )

 bootstrap addSlotsTo: bootstrap stub -> 'globals' -> 'modules' -> 'webHosts' -> () From: ( | {
         'ModuleInfo: Module: webHosts InitialContents: InitializeToExpression: (_CurrentTimeString)\x7fVisibility: public'

         fileInTimeString <- _CurrentTimeString.
        } | )

 bootstrap addSlotsTo: bootstrap stub -> 'globals' -> 'modules' -> 'webHosts' -> () From: ( | {
         'ModuleInfo: Module: webHosts InitialContents: FollowSlot'

         myComment <- ''.
        } | )

 bootstrap addSlotsTo: bootstrap stub -> 'globals' -> 'modules' -> 'webHosts' -> () From: ( | {
         'ModuleInfo: Module: webHosts InitialContents: FollowSlot'

         postFileIn = ( |
            | resend.postFileIn).
        } | )

 bootstrap addSlotsTo: bootstrap stub -> 'globals' -> 'modules' -> 'webHosts' -> () From: ( | {
         'ModuleInfo: Module: webHosts InitialContents: FollowSlot\x7fVisibility: public'

         revision <- '$Revision: 30.1 $'.
        } | )

 bootstrap addSlotsTo: bootstrap stub -> 'globals' -> 'modules' -> 'webHosts' -> () From: ( | {
         'ModuleInfo: Module: webHosts InitialContents: FollowSlot\x7fVisibility: private'

         subpartNames <- ''.
        } | )

 bootstrap addSlotsTo: bootstrap stub -> 'globals' -> () From: ( | {
         'Category: platform\x7fCategory: graphical interface\x7fModuleInfo: Module: webHosts InitialContents: FollowSlot\x7fVisibility: public'

         webGlobals = bootstrap setObjectAnnotationOf: bootstrap stub -> 'globals' -> 'webGlobals' -> () From: ( |
             {} = 'ModuleInfo: Creator: globals webGlobals.
'.
            | ) .
        } | )



 '-- Side effects'

 globals modules webHosts postFileIn
