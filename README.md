# web-backend-plugin

A web (browser) Morphic backend for [Self](https://github.com/russellallen/self),
packaged as a runtime-loadable **oop-library plugin**: an embedded civetweb
HTTP+WebSocket server ships a compact binary opcode stream to an HTML5-canvas
client, and browser input flows back into the Morphic event loop.  No VM
rebuild is needed — any Self VM with the oop-libraries mechanism (the self64
`vm-plugins` branch) can serve the web desktop.

Ported from self64's `web-backend` branch, where the same backend was compiled
into the VM as a dedicated `SELF_WEB` build.

## Layout

| Directory | Contents |
|---|---|
| `plugin/` | the plugin (→ `libweb.dylib` / `libweb.so`): `webplugin.cpp`, `web_client.hh` (browser client), `civetweb/`, `Makefile` |
| `objects/` | the Self side: `webPlugin.self` (dlopen + fctProxy binding), the Morphic modules (`webHosts`, `web`, `webFont`, `webCanvas`, `webEvents`), and the entry scripts `webStart.self` / `buildWebSnapshot.self` |

## Build

The ABI headers (`selfLib.h` / `selfHelpers.h`) come from a self64 checkout,
expected as a sibling directory:

    cd plugin && make                      # uses ../../self64/vm-plugins/include
    cd plugin && make SELF_INCLUDE=/path/to/vm-plugins/include

## Run

From the self64 repo root, with this repo beside it:

    Self -s objects/auto.snap64 -f ../web-backend-plugin/objects/webStart.self

then open `http://localhost:9876/owner/0/0`.  `/` lists the provisioned seats.

Environment: `SELF_WEB_PORT` (or a full `SELF_WEB_LISTEN` civetweb spec) picks
the port; `SELF_WEB_PLUGIN_DIR` points at this repo's root if the VM runs from
somewhere else; under `-T` lockdown `plugin/` must be trusted.

For a self-contained snapshot (`Self -s web.snap64`, no `-f`):

    Self -s objects/auto.snap64 -f ../web-backend-plugin/objects/buildWebSnapshot.self
