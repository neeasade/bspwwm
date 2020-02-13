;; -*- mode: fennel -*-

;; reminder: you can have macros in another file with
;; require-macros -- check that out for like
;; (wlroots.wlr_thing 1 2) --> (wlr thing 1 2)
;; and additionally maybe (thing &arst) ->> (thing (& arst))

;;  notes
;; the same: (tset state "a" 1) (tset state :a 1)

(global state
        {
         :app {}
         ;; running stuff/handles
         :wl {}
         }
        )

(local ffi (require "ffi"))
(local io  (require "io"))
(local math (require "math"))
(local fun (require "fun"))

(let [f (io.open "defs.h.out" "r")]
  (ffi.cdef (f.read f "*all")))

(lambda from-cpath [name]
  (package.searchpath name package.cpath))

;; (lambda ffi-address [cdata]
;;   (tonumber (ffi.cast "intptr_t" (ffi.cast "void *" cdata))))

;; lmao
(lambda & [cdata]
  (ffi.cast
   (string.format "%s *"
                  (-> cdata
                      ffi.typeof
                      tostring
                      ;; eg "ctype<struct wlr_list>"
                      (string.gsub "ctype<" "")
                      (string.gsub ">" "")
                      ))
   cdata
   ))

(local wlroots (ffi.load (from-cpath "wlroots")))
(local wayland (ffi.load (from-cpath "wayland-server")))
(local xkbcommon (ffi.load (from-cpath "xkbcommon")))
(local fennelview (require "fennelview"))

(global pp (lambda [x] (print (fennelview x))))

(fn assoc [tbl k v ...]
  (tset tbl k v)
  (if ...
      (assoc tbl (unpack [...]))
      tbl))

(lambda set-default-keymap [keyboard]
  (let [rules (ffi.new "struct xkb_rule_names" {})
        ;; -- rules.rules = getenv("XKB_DEFAULT_RULES");
        ;; -- rules.model = getenv("XKB_DEFAULT_MODEL");
        ;; -- rules.layout = getenv("XKB_DEFAULT_LAYOUT");
        ;; -- rules.variant = getenv("XKB_DEFAULT_VARIANT");
        ;; -- rules.options = getenv("XKB_DEFAULT_OPTIONS");
        context (xkbcommon.xkb_context_new 0)
        keymap (and context
                    (xkbcommon.xkb_keymap_new_from_names context rules 0))

        ret (if keymap
                (wlroots.wlr_keyboard_set_keymap keyboard keymap)
                (values nil (if context
                                "Couldn't create keymap"
                                "Couldn't create xkb context")))]
    (and keymap (xkbcommon.xkb_keymap_unref keymap))
    (and context (xkbcommon.xkb_context_unref context))
    ret))

(lambda init []
  (wlroots.wlr_log_init ffi.C.WLR_DEBUG nil)

  ;; struct tinywl_server server
  ;; /* The Wayland display is managed by libwayland. It handles accepting
  ;; * clients from the Unix socket, manging Wayland globals, and so on. */
  ;; server.wl_display = wl_display_create()
  (let [display (wayland.wl_display_create)
        backend (wlroots.wlr_backend_autocreate display nil)
        renderer (wlroots.wlr_backend_get_renderer backend)]

    (wlroots.wlr_renderer_init_wl_display renderer display)
    (wlroots.wlr_compositor_create display renderer)
    (wlroots.wlr_data_device_manager_create display)

    ;; gross
    (tset state :wl
          (assoc (. state :wl)
                 :display display
                 :backend backend
                 :renderer renderer)))

  (tset state :wl :output_layout (wlroots.wlr_output_layout_create))

  ;; this works! yay
  (local testlist (ffi.new "struct wlr_list"))
  (wlroots.wlr_list_init (& testlist))
  (= 10 testlist.capacity)

  ;; arst: testing making a wl list list:

  ;; /* Configure a listener to be notified when new outputs are available on the
  ;;  * backend. */
  ;; wl_list_init(&server.outputs);
  ;; server.new_output.notify = server_new_output;
  ;; wl_signal_add(&server.backend->events.new_output, &server.new_output);

  ;; /* Set up our list of views and the xdg-shell. The xdg-shell is a Wayland
  ;; * protocol which is used for application windows. For more detail on
  ;; * shells, refer to my article:
  ;; *
  ;; * https://drewdevault.com/2018/07/29/Wayland-shells.html
  ;; */
  ;; wl_list_init(&server.views);
  ;; server.xdg_shell = wlr_xdg_shell_create(server.wl_display);
  ;; server.new_xdg_surface.notify = server_new_xdg_surface;
  ;; wl_signal_add(&server.xdg_shell->events.new_surface,
  ;;               &server.new_xdg_surface);

  ;; /*
  ;; * Creates a cursor, which is a wlroots utility for tracking the cursor
  ;; * image shown on screen.
  ;; */
  ;; server.cursor = wlr_cursor_create();
  ;; wlr_cursor_attach_output_layout(server.cursor, server.output_layout);

  ;; /* Creates an xcursor manager, another wlroots utility which loads up
  ;; * Xcursor themes to source cursor images from and makes sure that cursor
  ;; * images are available at all scale factors on the screen (necessary for
  ;;                                                                      * HiDPI support). We add a cursor theme at scale factor 1 to begin with. */
  ;; server.cursor_mgr = wlr_xcursor_manager_create(NULL, 24);
  ;; wlr_xcursor_manager_load(server.cursor_mgr, 1);

  ;; /*
  ;; * wlr_cursor *only* displays an image on screen. It does not move around
  ;; * when the pointer moves. However, we can attach input devices to it, and
  ;; * it will generate aggregate events for all of them. In these events, we
  ;; * can choose how we want to process them, forwarding them to clients and
  ;; * moving the cursor around. More detail on this process is described in my
  ;; * input handling blog post:
  ;; *
  ;; * https://drewdevault.com/2018/07/17/Input-handling-in-wlroots.html
  ;; *
  ;; * And more comments are sprinkled throughout the notify functions above.
  ;; */
  ;; server.cursor_motion.notify = server_cursor_motion;
  ;; wl_signal_add(&server.cursor->events.motion, &server.cursor_motion);
  ;; server.cursor_motion_absolute.notify = server_cursor_motion_absolute;
  ;; wl_signal_add(&server.cursor->events.motion_absolute,
  ;;               &server.cursor_motion_absolute);
  ;; server.cursor_button.notify = server_cursor_button;
  ;; wl_signal_add(&server.cursor->events.button, &server.cursor_button);
  ;; server.cursor_axis.notify = server_cursor_axis;
  ;; wl_signal_add(&server.cursor->events.axis, &server.cursor_axis);
  ;; server.cursor_frame.notify = server_cursor_frame;
  ;; wl_signal_add(&server.cursor->events.frame, &server.cursor_frame);

  ;; /*
  ;; * Configures a seat, which is a single "seat" at which a user sits and
  ;; * operates the computer. This conceptually includes up to one keyboard,
  ;; * pointer, touch, and drawing tablet device. We also rig up a listener to
  ;; * let us know when new input devices are available on the backend.
  ;; */
  ;; wl_list_init(&server.keyboards);
  ;; server.new_input.notify = server_new_input;
  ;; wl_signal_add(&server.backend->events.new_input, &server.new_input);
  ;; server.seat = wlr_seat_create(server.wl_display, "seat0");
  ;; server.request_cursor.notify = seat_request_cursor;
  ;; wl_signal_add(&server.seat->events.request_set_cursor,
  ;;               &server.request_cursor);

  ;; /* Add a Unix socket to the Wayland display. */
  ;; const char *socket = wl_display_add_socket_auto(server.wl_display);
  ;; if (!socket) {
  ;;       	wlr_backend_destroy(server.backend);
  ;;       	return 1;
  ;;               }

  ;; /* Start the backend. This will enumerate outputs and inputs, become the DRM
  ;; * master, etc */
  ;; if (!wlr_backend_start(server.backend)) {
  ;;                                          wlr_backend_destroy(server.backend);
  ;;                                          wl_display_destroy(server.wl_display);
  ;;                                          return 1;
  ;;                                          }

  ;; /* Set the WAYLAND_DISPLAY environment variable to our socket and run the
  ;; * startup command if requested. */
  ;; setenv("WAYLAND_DISPLAY", socket, true);
  ;; if (startup_cmd) {
  ;;                   if (fork() == 0) {
  ;;                                     execl("/bin/sh", "/bin/sh", "-c", startup_cmd, (void *)NULL);
  ;;                                     }
  ;;                   }
  ;; /* Run the Wayland event loop. This does not return until you exit the
  ;; * compositor. Starting the backend rigged up all of the necessary event
  ;; * loop configuration to listen to libinput events, DRM events, generate
  ;; * frame events at the refresh rate, and so on. */
  ;; wlr_log(WLR_INFO, "Running Wayland compositor on WAYLAND_DISPLAY=%s",
  ;;                   socket);
  ;; wl_display_run(server.wl_display);

  ;; /* Once wl_display_run returns, we shut down the server. */
  ;; wl_display_destroy_clients(server.wl_display);
  ;; wl_display_destroy(server.wl_display);
  )

(print "ahahahah")
(init)
