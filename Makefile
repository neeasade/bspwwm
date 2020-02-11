FENNEL_SRCS=bspwwm.fnl
LUA_SRCS=$(patsubst %.fnl,%.fnl.lua,$(FENNEL_SRCS))
PROTOCOLS=$(shell pkg-config wayland-protocols --variable=datarootdir)

default: bspwwm

LIBS=$(shell pkg-config --libs luajit) \
     $(shell pkg-config --libs wayland-server) \
     $(shell pkg-config --libs xkbcommon)

CFLAGS=$(shell pkg-config --cflags xkbcommon) \
       $(shell pkg-config --cflags wayland-server) \
       $(shell pkg-config --cflags wlroots) \
	-I .

%.fnl.lua:%.fnl
	$(FENNEL) --compile $< > /tmp/$$PPID
	mv /tmp/$$PPID $@

xdg-shell-protocol.h:
	wayland-scanner server-header $(PROTOCOLS)/wayland-protocols/stable/xdg-shell/xdg-shell.xml $@

xdg-shell-unstable-v6-protocol.h:
	wayland-scanner server-header $(PROTOCOLS)/wayland-protocols/unstable/xdg-shell/xdg-shell-unstable-v6.xml  $@

defs.h.out: xdg-shell-unstable-v6-protocol.h xdg-shell-protocol.h Makefile
%.h.out: %.h
	$(CC) $(CFLAGS) -P -E - < $< | sed -e 's/static \([0-9]\+\)/\1/g' |   cat -s > /tmp/$$PPID
	mv /tmp/$$PPID $@

TAGS:
	etags $$(find $$(pkg-config --variable=includedir wlroots) $$(pkg-config --variable=includedir wayland-server) -name \*.[ch])


bspwwm: $(LUA_SRCS) defs.h.out
	echo "#!/usr/bin/env luajit" > bspwwm.tmp
	for i in $(LUA_SRCS) ; \
	  do ( echo "dofile('./$$i')" >> bspwwm.tmp ) ; \
	done
	mv bspwwm.tmp $@ && chmod +x $@
