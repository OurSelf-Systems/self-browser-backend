# The Self oop-library ABI headers (selfLib.h / selfHelpers.h) live in the
# self64 tree, expected as a sibling checkout; override for other layouts.
SELF_INCLUDE ?= ../../self64/vm-plugins/include
CIVET_DEFS = -DUSE_WEBSOCKET -DNO_SSL -DNO_CGI -DUSE_IPV6 -DUSE_X_DOM_SOCKET
CFLAGS   = -O2 -fPIC -Wall -Icivetweb $(CIVET_DEFS)
CXXFLAGS = -O2 -fPIC -Wall -Wextra -I$(SELF_INCLUDE) -Icivetweb $(CIVET_DEFS)

UNAME := $(shell uname -s)

ifeq ($(UNAME),Darwin)
LIB = libweb.dylib
else
LIB = libweb.so
endif

OBJS = webplugin.o civetweb.o

$(LIB): $(OBJS)
	$(CXX) -shared -o $@ $(OBJS) -lpthread
ifeq ($(UNAME),Darwin)
	codesign -s - $@ 2>/dev/null || true
endif

webplugin.o: webplugin.cpp web_client.hh $(SELF_INCLUDE)/selfLib.h $(SELF_INCLUDE)/selfHelpers.h
	$(CXX) $(CXXFLAGS) -c webplugin.cpp -o $@

civetweb.o: civetweb/civetweb.c civetweb/civetweb.h
	$(CC) $(CFLAGS) -c civetweb/civetweb.c -o $@

clean:
	rm -f libweb.dylib libweb.so *.o
