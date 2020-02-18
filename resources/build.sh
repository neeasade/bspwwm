#!/bin/sh
# generate bindings for libraries as data
# inspo: https://github.com/telent/fenestra/blob/master/Makefile

cd "$(dirname $([ -L $0  ] && readlink -f $0 || echo $0))"

tags() {
    etags $(find \
	    $(pkg-config --variable=includedir wlroots) \
	    $(pkg-config --variable=includedir wayland-server) \
	    -name \*.[ch])
}

# wowie wow sir why don't you just use make
vdo() {
    echo "$*"
    "$@"
}

mark() {
    echo "arst $*"
}

# old ref
# (local wlroots (ffi.load (from-cpath "wlroots")))
# (local wayland (ffi.load (from-cpath "wayland-server")))
# (local xkbcommon (ffi.load (from-cpath "xkbcommon")))

# cheating by using the ref from shell.nix
# WLROOTS_RESULT = "${wlroots}";
# XKBCOMMON_RESULT = "${libxkbcommon}";

# WAYLAND_RESULT = "${wayland}";
# wayland-scanner server-header $(PROTOCOLS)/wayland-protocols/stable/xdg-shell/xdg-shell.xml

# XKBCOMMON_RESULT = "${libxkbcommon}";

# note: all the protocols I see listed
# ./unstable/xdg-shell/xdg-shell-unstable-v6.xml
# ./unstable/xdg-shell/xdg-shell-unstable-v5.xml
# ./unstable/tablet/tablet-unstable-v1.xml
# ./unstable/tablet/tablet-unstable-v2.xml
# ./unstable/fullscreen-shell/fullscreen-shell-unstable-v1.xml
# ./unstable/pointer-constraints/pointer-constraints-unstable-v1.xml
# ./unstable/idle-inhibit/idle-inhibit-unstable-v1.xml
# ./unstable/xwayland-keyboard-grab/xwayland-keyboard-grab-unstable-v1.xml
# ./unstable/keyboard-shortcuts-inhibit/keyboard-shortcuts-inhibit-unstable-v1.xml
# ./unstable/linux-dmabuf/linux-dmabuf-unstable-v1.xml
# ./unstable/xdg-output/xdg-output-unstable-v1.xml
# ./unstable/xdg-decoration/xdg-decoration-unstable-v1.xml
# ./unstable/input-method/input-method-unstable-v1.xml
# ./unstable/linux-explicit-synchronization/linux-explicit-synchronization-unstable-v1.xml
# ./unstable/xdg-foreign/xdg-foreign-unstable-v1.xml
# ./unstable/xdg-foreign/xdg-foreign-unstable-v2.xml
# ./unstable/pointer-gestures/pointer-gestures-unstable-v1.xml
# ./unstable/primary-selection/primary-selection-unstable-v1.xml
# ./unstable/input-timestamps/input-timestamps-unstable-v1.xml
# ./unstable/text-input/text-input-unstable-v1.xml
# ./unstable/text-input/text-input-unstable-v3.xml
# ./unstable/relative-pointer/relative-pointer-unstable-v1.xml
# ./stable/xdg-shell/xdg-shell.xml
# ./stable/viewporter/viewporter.xml
# ./stable/presentation-time/presentation-time.xml

protocol_root="$(pkg-config wayland-protocols --variable=datarootdir)/wayland-protocols"
protocol_wants="
stable/xdg-shell/xdg-shell.xml
unstable/xdg-shell/xdg-shell-unstable-v6.xml
"

mkdir -p ./protocol
# protocol stuff
# should this be somewhere else?
for file in $protocol_wants; do
    vdo wayland-scanner server-header "${protocol_root}/${file}" "./protocol/$(basename -s .xml "$file")-protocol.h"
done

mark wayland-server
cat<<EOF | gcc -P -E $(pkg-config --cflags xkbcommon) -I./protocol - >./bindings/wayland-server.h
#include <wayland-server-core.h>
EOF

mark xkbcommon
cat<<EOF | gcc -P -E $(pkg-config --cflags xkbcommon) - >./bindings/xkbcommon.h
#include <xkbcommon/xkbcommon.h>
EOF

mark wlroots
cat<<EOF | gcc -P -E $(pkg-config --cflags wayland-server) $(pkg-config --cflags wlroots) -I./protocol - >./bindings/wlroots.h
#define WLR_USE_UNSTABLE 1
#include <wlr/render/wlr_renderer.h>
#include <wlr/types/wlr_compositor.h>
#include <wlr/types/wlr_cursor.h>
#include <wlr/types/wlr_data_device.h>
#include <wlr/types/wlr_idle.h>
#include <wlr/types/wlr_input_device.h>
#include <wlr/types/wlr_keyboard.h>
#include <wlr/types/wlr_matrix.h>
#include <wlr/types/wlr_output.h>
#include <wlr/types/wlr_output_layout.h>
#include <wlr/types/wlr_list.h>
#include <wlr/types/wlr_pointer.h>
#include <wlr/types/wlr_seat.h>
#include <wlr/types/wlr_surface.h>
#include <wlr/types/wlr_xcursor_manager.h>
#include <wlr/types/wlr_xdg_shell.h>
#include <wlr/types/wlr_xdg_shell_v6.h>
#include <wlr/util/log.h>
#include <wlr/xcursor.h>
EOF

# preserving this change from the old stuff, but I'm not sure what it was for
# having inspected it once, I don't see it actually doing anything..
cd ./bindings
sed -i -e 's/static \([0-9]\+\)/\1/g' *
cd ..

# header_to_table() {
#     # todo: python cdef?
#     echo nop
# }
