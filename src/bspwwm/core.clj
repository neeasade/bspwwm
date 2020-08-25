(ns bspwwm.core
  (:require [clojure.string :as s]
            [clojure.math.combinatorics :as c]
            [clojure.java.shell :as shell]
            [medley.core :as m]
            )
  (:import [jnr.ffi LibraryLoader LibraryOption]
           [jnr.ffi.annotations
            In Out
            Pinned LongLong
            ;; Link
            ]
           [jnr.ffi.types
            size_t
            u_int8_t
            u_int16_t
            u_int32_t
            ])
  ;; (:gen-class)
  )

;; jnr.ffi.types.

;; uint32_t jnr.ffi.Struct
;; In

;; uint32_t
;; jnr.ffi.types.u_int16_t

;; only using this in a one-off to generate bindings
(defn generate-bindings []
  ;; eg
  ;; int wl_event_source_fd_update(struct wl_event_source *source, uint32_t mask);
  ;; to
  ;;   [^void wlr_log_init [^int verbosity]]
  (defn cdef [cdef-string]
    (let [matches (first (re-seq #"([a-z]+)[ ]+([a-zA-Z_]+)\((.*)\);" cdef-string))
          type (nth matches 1)
          name (nth matches 2)
          args (nth matches 3)
          args-parsed
          (map
           ;; asume eg struct wl_event_source *source,
           #(if (s/starts-with? % "struct")
              ;; ^bytes ^{Pinned {}} buf
              ;; "FIXME"
              (format "^%s ^{Pinned {}} %s"
                      ;; (second (re-seq #"[0-9a-zA-Z_]+" %))
                      "bytes"
                      (last (re-seq #"[a-zA-Z_]+" %))
                      )

              (format "^%s %s"
                      (cond

                        ;; default:
                        true (s/replace
                              (first (re-seq #"[0-9a-zA-Z_]+" %))
                              "uint" "u_int")
                        )

                      (last (re-seq #"[a-zA-Z_]+" %)) ;; match jnr
                      )
              )
           (map s/trim
                (s/split args #",")
                )
           )
          ]
      (format "[^%s %s \n[%s]]\n"
              type
              name
              (s/join "\n" args-parsed)
              )

      ))

  (cdef "int wl_event_source_fd_update(struct wl_event_source *source, uint32_t mask);")

  ;; TODO: struct constructing/referencing
  ;; you must make a class off of jnr Struct type?

  (defn generate-method-calls [header dest]
    (->>
     ;; "./resources/bindings/wayland-server.h"
     header
     (slurp)
     (re-seq #"\n[a-z]+[ \n]+[a-zA-Z_]+\(.*\);")
     (map #(s/replace % "\n" " "))
     (map cdef)
     ;; first
     (s/join "\n")
     (format "'[%s]")
     (spit dest)
     ))

  (generate-method-calls
   "./resources/bindings/wayland-server.h"
   "./resources/bindings/wayland-server-methods.edn")

  ;; todo: void pointers correctly
  ;; todo: wlr_list_insert didn't make it? investigate
  (generate-method-calls
   "./resources/bindings/wlroots.h"
   "./resources/bindings/wlroots-methods.edn")

  (generate-method-calls
   "./resources/bindings/xkbcommon.h"
   "./resources/bindings/xkbcommon-methods.edn")
  )

(def ^:private bound-byte-type-syms
  '[bytes java.nio.ByteBuffer])

(defn ^:private permuted-byte-types
  "Given a method signature, return signatures for all bound byte types.
  Signature should be as per [[bound-fns]], with byte arguments annotated with
  `{:tag 'bytes}` in their metadata (note: the symbol, not the fn)."
  [[name args]]
  (let [byte-args (filter (comp #{'bytes} :tag meta) args)]
    (for [types (c/selections bound-byte-type-syms (count byte-args))
          :let [arg->type (zipmap byte-args types)
                ann (fn [arg]
                      (let [tag (get arg->type arg (:tag (meta arg)))]
                        (vary-meta arg assoc :tag tag)))]]
      [name (mapv ann args)])))

(def ^:private raw-bound-fns
  "See [[bound-fns]], but without the permutations."
  '[
    [^void wlr_log_init [^int verbosity]]
    ;; [^int wlr_log_get_verbosity [^int verbosity]]

    [^static ^void log_wl [^bytes ^{Pinned {}} fmt
                           ^bytes ^{Pinned {}} args
                           ]]
    ]
  ;; (-> "./resources/bindings/wlroots-methods.edn" slurp read-string)
  )

(def ^:private bound-fns
  "A mapping of type- and jnr.ffi-annotated bound method symbols to
  respective argspec.
  This exists so that tooling (like magic macro helpers) can easily
  inspect caesium allegedly binds. That can be done by reflecting on
  the interface too, but that's significantly less convenient;
  Clojure's reflection tools don't show annotations, and we always use
  the data in metadata-annotated form anyway (both to create the
  interface and to bind fns to vars).
  This has to be a seq and not a map, because the same key (symbol,
  method name) might occur with multiple values (e.g. when binding the
  same char* fn with different JVM byte types)."
  (mapcat permuted-byte-types raw-bound-fns))

(defmacro ^:private defwlroots []
  []
  `(definterface ~'Wlroots ~@bound-fns))

(defwlroots)

(defn ^:private load-wlroots
  "Load native libwlroots library."
  ([]
   (load-wlroots "/nix/store/2sppkxs3nypzm9z8ksjfcqznp5vbghqw-wlroots-0.10.0/lib/libwlroots.so")
   ;; (load-wlroots "wlroots")
   )
  ([lib]
   (try
     (->
      (LibraryLoader/create Wlroots)
      (.option LibraryOption/IgnoreError true)
      (.load lib))
     (catch Exception e
       (throw (ClassNotFoundException. "unable to load native libwlroots; is it installed?"))))))

(def ^Wlroots wlroots
  "The wlroots library singleton instance."
  (load-wlroots
   "/nix/store/2sppkxs3nypzm9z8ksjfcqznp5vbghqw-wlroots-0.10.0/lib/libwlroots.so"
   ;; try setting LD_LIBRARY_PATH to get this dynamic resolution
   ;; steal the solution from your adhoc nix thingy
   ;; "wlroots"
   ))

;; (macroexpand-1 '(call! wlr_log_init 1))
;; (.wlr_log_init bspwwm.core/wlroots)

(.wlr_log_init bspwwm.core/wlroots 3)

(.log_stderr bspwwm.core/wlroots 3 "%s" "wuck")
(.wlr_log bspwwm.core/wlroots 3 "%s" "wuck")

(defn ^:private java-call-sym
  "Creates the Clojure Java method call syntax to call a method on the
  libsodium binding."
  [c-name]
  (symbol (str "." c-name)))

(defmacro call!
  "Produces a form for calling named fn with lots of magic:

  * The fn-name is specified using its short name, which is resolved
    against the ns as per [[defconsts]].
  * All bufs are annotated as ByteBuffers.
  * Buffer lengths are automatically added."
  [fn-name & args]

  (let
      [
       c-name (s/replace (name fn-name) "-" "_")
       ;; (c-name *ns* fn-name)
       [_ c-args] (m/find-first (comp #{c-name} first) raw-bound-fns)
       normalize-tag (fn [k] (get {'bytes 'java.nio.ByteBuffer} k k))
       tag (fn [arg] (-> (m/find-first #{arg} c-args) meta :tag normalize-tag))
       call-args (for [arg c-args]
                   (cond
                     (some #{arg} args)
                     (with-meta arg {:tag (tag arg)})

                     (= 'long (tag arg))
                     (let [arg-sym (symbol (s/replace (name arg) #"len$" ""))]
                       `(long (caesium.byte-bufs/buflen ~arg-sym)))

                     (= 'jnr.ffi.byref.LongLongByReference (tag arg))
                     nil))]
    `(~(java-call-sym c-name) wlroots ~@call-args)))

(defn -main
  "I don't do a whole lot ... yet."
  [& args]
  (println "Hello, World!"))
