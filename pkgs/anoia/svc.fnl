(local inotify (require :inotify))
(local { : file-exists? : dirname : append-path } (require :anoia))
(local { : file-type : dir : mktree &as fs } (require :anoia.fs))
(local { : readlink } (require :lualinux))

(fn read-line [name]
  (with-open [f (assert (io.open name :r) (.. "can't open file " name))]
    (f:read "*l")))


;; If the directory is missing, we cannot add a inotify watch
;; for it.  We need a watch that opens the parent if the pathname is missing,
;; and it needs to be the resolved path not the syntactic parent.

;; If the directory is not missing, then having a watch on the
;; parent may result in extra wakeups but should only affect
;; efficiency not correctness

;; Each time the directory may have been added we need to update
;; watches. If it's been removed, the watch will be removed
;; automatically. inotify_add_watch when it already exists will modify
;; instead of making a new one, so we can treat it as idempotent


(fn resolve-link [pathname]
  (if (= (file-type pathname) :link)
      (readlink pathname)
      pathname))

(fn watch-fsevents [directory-name]
  (let [handle (inotify.init)
        parent-name (dirname (resolve-link directory-name))
        refresh (fn []
                  (handle:addwatch directory-name
                                   inotify.IN_CREATE
                                   inotify.IN_MOVE
                                   inotify.IN_DELETE
                                   inotify.IN_DELETE_SELF
                                   inotify.IN_MOVED_FROM
                                   inotify.IN_MOVED_TO
                                   inotify.IN_CLOSE_WRITE)
                  (handle:addwatch parent-name
                                   inotify.IN_CREATE
                                   inotify.IN_DELETE))]
    ;; if you are using poll() to check for events on this
    ;; watcher and on other events at the same time, be sure
    ;; to call fileno each time around the loop instead
    ;; of only once
    {
     :fileno #(do (refresh) (handle:fileno))
     :wait #(do (refresh) (handle:read))
     :close #(handle:close)
     }))

(fn write-value [pathname value]
  (mktree (dirname pathname))
  (match (type value)
    "string"
    (with-open [f (assert (io.open pathname :w) (.. "can't open " pathname))]
      (f:write value))
    "table" (each [k v (pairs value)]
              (write-value (append-path pathname k) v))))

(fn read-value [pathname]
  (case (file-type pathname)
    nil nil
    :directory
    (collect [f (fs.dir pathname)]
      (when (not (or (= f ".") (= f "..")))
        (values f (read-value (append-path pathname f)))))
    :file
    (read-line pathname)
    :link
    (read-line pathname)
    unknown
    (error (.. "can't read " pathname " of kind \"" unknown.mode "\""))))

(fn events [self]
  (coroutine.wrap
   #(while true
      (while (not (self:ready?)) (self:wait))
      (coroutine.yield self)
      (self:wait))))

(fn open [directory]
  (let [outputs-dir (append-path directory ".outputs")
        has-file? #(file-exists? (append-path directory $1))
        watcher (watch-fsevents outputs-dir)
        properties-dir (append-path directory ".properties")]
    {
     :ready? (fn [self]
               (and (has-file? ".outputs/state")
                    (not (has-file? ".outputs/.lock"))))
     :property (fn [_ filename]
                 (read-value (append-path properties-dir filename)))
     :output (fn [_ filename new-value]
               (if new-value
                   (write-value (append-path outputs-dir filename) new-value)
                   (or
                    (read-value (append-path outputs-dir filename))
                    (read-value (append-path properties-dir filename)))))
     :wait #(watcher:wait)
     :close #(watcher:close)
     :fileno #(watcher:fileno)
     : directory
     : events
     }))

{ : open }
