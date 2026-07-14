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

| Piece | Files |
|---|---|
| The plugin (→ `libweb.dylib` / `libweb.so`) | `webplugin.cpp`, `web_client.hh`, `civetweb/`, `Makefile` |
| Self-side binding (dlopen + fctProxy wrappers) | `webPlugin.self` |
| Self modules (drawable/gc, fonts, canvases, events) | `webHosts.self`, `web.self`, `webFont.self`, `webCanvas.self`, `webEvents.self` |
| Entry scripts | `webStart.self` (file in + open), `buildWebSnapshot.self` (bake `web.snap64`) |

## Build

The ABI headers (`selfLib.h` / `selfHelpers.h`) come from a self64 checkout,
expected as a sibling directory:

    make                                   # uses ../self64/vm-plugins/include
    make SELF_INCLUDE=/path/to/vm-plugins/include

## Run

From the self64 repo root, with this repo beside it:

    Self -s objects/auto.snap64 -f ../web-backend-plugin/webStart.self

then open `http://localhost:9876/owner/0/0`.  `/` lists the provisioned seats.

Environment: `SELF_WEB_PORT` (or a full `SELF_WEB_LISTEN` civetweb spec) picks
the port; `SELF_WEB_PLUGIN_DIR` points at this repo if the VM runs from
somewhere else; under `-T` lockdown this directory must be trusted.

For a self-contained snapshot (`Self -s web.snap64`, no `-f`):

    Self -s objects/auto.snap64 -f ../web-backend-plugin/buildWebSnapshot.self
