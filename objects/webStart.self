"Startup script for the web (browser GUI) backend.

   From a self64 checkout beside this repo:
   Self -s objects/auto.snap64 -f ../web-backend-plugin/objects/webStart.self

 Files in the web Morphic backend modules and opens the Self desktop in the browser.
 The whole backend lives in this repo: the oop-library plugin
 (plugin/libweb.dylib|.so -- build it with make in plugin/ first; the first
 window open dlopens it) and the Self modules in objects/, filed in below.

 Configuration via the environment:
   SELF_WEB_PLUGIN_DIR  this repo's root: the Self modules (objects/) AND
                        libweb.dylib|.so (plugin/).  Default
                        '../web-backend-plugin', relative to the VM's working
                        directory -- i.e. launch from the self64 repo root;
                        plugin/ must be a trusted directory if the VM runs
                        under -T lockdown.
   SELF_OBJECTS_DIR     directory holding the Self objects tree   (default 'objects')
   SELF_WEB_LISTEN      civetweb listening_ports spec -- a comma list of port / ip:port /
                        [ipv6]:port / +port (v4+v6) / x<path> (unix socket).
                        e.g. '9876', '127.0.0.1:9876', '127.0.0.1:9876,[::1]:9876'
   SELF_WEB_PORT        a bare port, used only if SELF_WEB_LISTEN is unset (default 9876)

 Then open  http://<host>:<port>/owner/0/0  in a browser."

[ | wd |
    wd: os environmentAt: 'SELF_WEB_PLUGIN_DIR' IfFail: '../web-backend-plugin'.
    bootstrap selfObjectsWorkingDir: (os environmentAt: 'SELF_OBJECTS_DIR' IfFail: 'objects').
    (wd, '/objects/webHosts.self')  _RunScript.
    (wd, '/objects/web.self')       _RunScript.
    (wd, '/objects/webPlugin.self') _RunScript.
    (wd, '/objects/webFont.self')   _RunScript.
    (wd, '/objects/webCanvas.self') _RunScript.
    (wd, '/objects/webEvents.self') _RunScript.
] value.

"A stable owner name so the base seat is predictably /owner/0/0."
users owner preferredName: 'owner'.

desktop openWebFromEnv.

"Add a second user 'alice' and register her for one window on world 0.
 ensureProvisionedWindows (run from the UI tick at webCanvas.self:230) will
 create her window and stamp the seat as 'alice/0/<displayIdx>' where
 displayIdx is her window's position in world 0's winCanvases list -- so with
 owner already holding display 0, alice's seat ends up at /alice/0/1.  Doing
 this via the auto-provisioning list (rather than calling
 provisionWindowForUser:OnWorld: directly here) keeps the morph mutation
 inside the UI process and self-heals after a snapshot resume."
"users addUserNamed:Password: is broken in core (it sends `password:` to
 userProfile, which has no such slot), so inline the user creation."
users team add: (userProfile copy name: 'alice').
webGlobals usersToProvision add: ('alice' & 0 & 1) asVector.

('Self web desktop ready on  ', webGlobals webDisplayName,
 '  -- open  http://<host>/  for a list of provisioned seats.') printLine.
