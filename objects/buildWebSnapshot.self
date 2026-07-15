"Build a self-contained web snapshot for the web (browser GUI) backend.

   From a self64 checkout beside this repo:
   Self -s objects/auto.snap64 -f ../self-browser-backend/objects/buildWebSnapshot.self

 Files in the web Morphic backend modules (the backend itself is the oop-library
 plugin plugin/libweb.dylib|.so in this repo -- build it with make in plugin/
 first), registers a scheduler-initial message that opens the web desktop fresh
 on resume (reading SELF_WEB_PORT, default 9876), and writes web.snap64 into the
 current directory.  Thereafter the desktop launches with no -f and no module
 file-in:

   SELF_WEB_PORT=9876 Self -s web.snap64
   # then open  http://localhost:9876/owner/0/0

 The desktop is deliberately left CLOSED at save time: opening fresh on resume (via
 the scheduler-initial openWebFromEnv) avoids the dead window handles and library
 proxies a saved-open snapshot would otherwise carry (openDisplay: re-dlopens the
 plugin), and lets the port be chosen at resume time.

 The plugin is dlopened from SELF_WEB_PLUGIN_DIR/plugin (default root:
 '../self-browser-backend', relative to the VM's working directory).  If the VM
 runs under -T lockdown, that directory must be trusted.

 (For quick dev iteration without rebuilding the snapshot, use webStart.self instead:
  Self -s objects/auto.snap64 -f ../self-browser-backend/objects/webStart.self)"

[ | wd |
    wd: os environmentAt: 'SELF_WEB_PLUGIN_DIR' IfFail: '../self-browser-backend'.
    bootstrap selfObjectsWorkingDir: (os environmentAt: 'SELF_OBJECTS_DIR' IfFail: 'objects').
    (wd, '/objects/webHosts.self')  _RunScript.
    (wd, '/objects/web.self')       _RunScript.
    (wd, '/objects/webPlugin.self') _RunScript.
    (wd, '/objects/webFont.self')   _RunScript.
    (wd, '/objects/webCanvas.self') _RunScript.
    (wd, '/objects/webEvents.self') _RunScript.
] value.

users owner preferredName: 'owner'.

"Open the web desktop fresh whenever this snapshot is resumed."
snapshotAction addSchedulerInitialMessage: message copy receiver: desktop Selector: 'openWebFromEnv'.

memory snapshotOptions fileName: 'web.snap64'.
memory writeSnapshot.
'web.snap64 written -- run:  Self -s web.snap64' printLine.
