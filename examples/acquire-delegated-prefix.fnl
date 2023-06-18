
(local inotify (require :inotify))

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


(fn merge [table1 table2]
  (collect [k v (pairs table2) &into table1]
    k v))

(fn parse-extra [s]
  (let [out {}]
    (each [name val (string.gmatch s ",(.-)=([^,]+)")]
      (tset out name val))
    out))

(fn parse-prefixes [prefixes]
  (icollect [val (string.gmatch prefixes "([^ ]+)")]
    (let [(prefix len preferred valid extra)
          (string.match val "(.-)::/(%d+),(%d+),(%d+)(.*)$")]
      (merge {: prefix : len : preferred : valid} (parse-extra extra))
      )))

;; Format: <prefix>/<length>,preferred,valid[,excluded=<excluded-prefix>/<length>][,class=<prefix class #>]

;; (parse-prefixes "2001:8b0:de3a:40dc::/64,7198,7198 2001:8b0:de3a:1001::/64,7198,7188,excluded=1/2,thi=10")


(fn file-exists? [name]
  (match (io.open name :r)
    f (do (f:close) true)
    _ false))


(fn read-line [name]
  (with-open [f (assert (io.open name :r) (.. "can't open file " name))]
    (f:read "*l")))

(var last-update 0)
(fn event-time [directory]
  (if (file-exists? (.. directory "/state"))
      (tonumber (read-line (.. directory "/last-update")))
      nil))

(fn wait-for-update [directory fsevents]
  (while (<= (or (event-time directory) 0) last-update)
    (fsevents:read))
  (set last-update (event-time directory))
  true)

(let [[state-directory lan-device] arg
      fsevents (watch-fsevents state-directory)]
  (while (wait-for-update state-directory fsevents)
    (match (read-line (.. state-directory "/state"))
      (where (or :bound :rebound :informed :updated :ra-updated))
      (let [[{ : prefix : len : preferred : valid }]
            (parse-prefixes (read-line (.. state-directory  "/prefixes")))]
        (os.execute (.. "ip address add " prefix "::1/" len
    		        " dev " lan-device)))
      _ (os.exit 1))))
