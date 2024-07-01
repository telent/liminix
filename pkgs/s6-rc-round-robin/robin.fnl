(local { : directory? : symlink } (require :anoia.fs))
(local { : assoc : system } (require :anoia))
(local inotify (require :inotify))

(fn parse-args [args]
  (match args
    ["-p" proxy & rest] (assoc (parse-args rest) :proxy proxy)
    backends { : backends }
    _  nil))

(fn %% [fmt ...] (string.format fmt ...))

(fn start-service [service]
  (let [(ok msg) (pcall system (%% "s6-rc-up-tree %q" service))]
    (when (not ok) (print msg))
    ok))

(fn stop-service [service]
  (let [(ok msg) (%% "s6-rc -b -d change %q" service)]
    (when (not ok) (print msg))
    ok))

(fn watch-fsevents [directory-name]
  (doto (inotify.init)
    (: :addwatch directory-name
       inotify.IN_CREATE
       inotify.IN_MOVE
       inotify.IN_DELETE
       inotify.IN_DELETE_SELF
       inotify.IN_MOVED_FROM
       inotify.IN_MOVED_TO
       inotify.IN_CLOSE_WRITE)))

(fn round-robin [els]
  (var i -1)
  (fn []
    (set i (% (+ 1 i) (# els)))
    (. els (+ 1 i))))

(fn run []
  (let [{ : proxy : backends } (parse-args arg)]
    (each [s (round-robin backends)]
      (print "ROBIN starting " s)
      (when (start-service s)
        (let [outputs-dir (.. "/run/services/outputs/" s)]
          (print "ROBIN started " s "expecting outputs in " outputs-dir)
          (with-open [watcher (watch-fsevents outputs-dir)]
            (symlink outputs-dir "active")
            (start-service proxy)
            (while (directory? outputs-dir)
              (print :ROBIN (watcher:read))))))
      ;; service failed to start, or started and finished
      (print "ROBIN finished " s "stopping proxy")
      (stop-service proxy)
      (os.remove "active")
      )))

{ : run }
