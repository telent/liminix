(local inotify (require :inotify))
(local { : file-exists? : dirname } (require :anoia))
(local { : file-type : dir : mktree &as fs } (require :anoia.fs))

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

(fn write-value [pathname value]
  (mktree (dirname pathname))
  (match (type value)
    "string"
    (with-open [f (assert (io.open pathname :w) (.. "can't open " pathname))]
      (f:write value))
    "table" (each [k v (pairs value)]
              (write-value (.. pathname "/" k) v))))

(fn read-value [pathname]
  (case (file-type pathname)
    nil nil
    :directory
    (collect [f (fs.dir pathname)]
      (when (not (or (= f ".") (= f "..")))
        (values f (read-value ( .. pathname "/" f)))))
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
  (let [watcher (watch-fsevents directory)
        has-file? (fn [filename] (file-exists? (.. directory "/" filename)))]
    {
     :wait #(watcher:read)
     :ready? (fn [self]
               (and (has-file? "state") (not (has-file? ".lock"))))
     :output (fn [_ filename new-value]
               (if new-value
                   (write-value (.. directory "/" filename) new-value)
                   (read-value (.. directory "/" filename))))
     :close #(watcher:close)
     :fileno #(watcher:fileno)
     : events
     }))

{ : open }
