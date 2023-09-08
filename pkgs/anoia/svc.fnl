(local inotify (require :inotify))
(local { : file-exists? } (require :anoia))
(local { : directory? } (require :anoia.fs))
(local lfs (require :lfs))

(fn read-line [name]
  (with-open [f (assert (io.open name :r) (.. "can't open file " name))]
    (f:read "*l")))

(fn watch-fsevents [directory-name]
  (let [handle (inotify.init)]
    (handle:addwatch directory-name
                     inotify.IN_CREATE
                     inotify.IN_MOVE
                     inotify.IN_DELETE
                     inotify.IN_DELETE_SELF
                     inotify.IN_MOVED_FROM
                     inotify.IN_MOVED_TO
                     inotify.IN_CLOSE_WRITE)
    handle))

(fn read-value [pathname]
  (case (lfs.symlinkattributes pathname)
    nil nil
    {:mode "directory"}
    (collect [f (lfs.dir pathname)]
      (when (not (or (= f ".") (= f "..")))
        (values f (read-value ( .. pathname "/" f)))))
    {:mode "file"}
    (read-line pathname)
    {:mode "link"}
    (read-line pathname)
    unknown
    (error (.. "can't read " pathname " of kind \"" unknown.mode "\""))))


(fn open [directory]
  (let [watcher (watch-fsevents directory)
        has-file? (fn [filename] (file-exists? (.. directory "/" filename)))]
    {
     :wait #(watcher:read)
     :ready? (fn [self]
               (and (has-file? "state") (not (has-file? ".lock"))))
     :output (fn [_ filename]
               (read-value (.. directory "/" filename)))
     :close #(watcher:close)
     }))

{ : open }
