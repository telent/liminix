(local inotify (require :inotify))
(local { : file-exists? } (require :anoia))
(local { : file-type : dir &as fs } (require :anoia.fs))
(local ll (require :lualinux))

(fn read-line [name]
  (with-open [f (assert (io.open name :r) (.. "can't open file " name))]
    (f:read "*l")))

(fn watch-fsevents [directory-name]
  (let [handle (inotify.init { :blocking false})]
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

(fn read-with-timeout [watcher]
  (let [fd (watcher:fileno)]
    (ll.pollin fd 5000)
    (watcher:read)))

(fn open [directory]
  (let [watcher (watch-fsevents directory)
        has-file? (fn [filename] (file-exists? (.. directory "/" filename)))]
    {
     :wait #(read-with-timeout watcher)
     :ready? (fn [self]
               (and (has-file? "state") (not (has-file? ".lock"))))
     :output (fn [_ filename]
               (read-value (.. directory "/" filename)))
     :close #(watcher:close)
     : events
     }))

{ : open }
