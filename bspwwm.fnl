;; -*- mode: fennel -*-

(local ffi (require "ffi"))
(local io  (require "io"))
(local math (require "math"))
(local fun (require "fun"))

(let [f (io.open "defs.h.out" "r")]
  (ffi.cdef (f.read f "*all")))

(lambda from-cpath [name]
  (package.searchpath name package.cpath))

(local wlroots (ffi.load (from-cpath "wlroots")))
(local wayland (ffi.load (from-cpath "wayland-server")))
(local xkbcommon (ffi.load (from-cpath "xkbcommon")))

(local fennelview (require "fennelview"))

(global pp (lambda [x] (print (fennelview x))))

(wlroots.wlr_log_init 3 nil)

(print "ahahahaha")
(+ 1 2)
