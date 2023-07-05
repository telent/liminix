(local inotify (require :inotify))
(local { : merge : split : file-exists? : system } (require :anoia))

(fn parse-prefix [str]
  (fn parse-extra [s]
    (let [out {}]
      (each [name val (string.gmatch s ",(.-)=([^,]+)")]
        (tset out name val))
      out))
  (let [(prefix len preferred valid extra)
        (string.match str "(.-)::/(%d+),(%d+),(%d+)(.*)$")]
    (merge {: prefix : len : preferred : valid} (parse-extra extra))))


;; Format: <prefix>/<length>,preferred,valid[,excluded=<excluded-prefix>/<length>][,class=<prefix class #>]

;;(parse-prefix "2001:8b0:de3a:40dc::/64,7198,7198")
;;(parse-prefix "2001:8b0:de3a:1001::/64,7198,7188,excluded=1/2,thi=10")

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

(fn watch-directory [pathname]
  (let [watcher (watch-fsevents pathname)]
    {
     :has-file? (fn [_ filename] (file-exists? (.. pathname "/" filename)))
     :wait-events (fn [] (watcher:read))
     :ready? (fn [self]
               (and (self:has-file? "state") (not (self:has-file? ".lock"))))
     :read-line (fn [_ filename] (read-line (.. pathname "/" filename)))
     :close #(watcher:close)
     }))

(local bound-states
       { :bound true
         :rebound true
         :informed true
         :updated true
         :ra-updated true
         })

; (local { : view } (require :fennel))

(fn changes [old-prefixes new-prefixes]
  (let [added {}
        deleted {}
        old-set (collect [_ v (ipairs old-prefixes)] (values v true))
        new-set (collect [_ v (ipairs new-prefixes)] (values v true))]
    (each [_ prefix (ipairs new-prefixes)]
      (if (not (. old-set prefix))
          (table.insert added (parse-prefix prefix))))
    (each [_ prefix (ipairs old-prefixes)]
      (if (not (. new-set prefix))
          (table.insert deleted (parse-prefix prefix))))
    (values added deleted)))

(let [[state-directory lan-device] arg
      dir (watch-directory state-directory)]
  (var prefixes [])
  (while true
    (while (not (dir:ready?)) (dir:wait-events))
    (if (. bound-states (dir:read-line "state"))
        (let [new-prefixes (split " " (dir:read-line "/prefixes"))
              (added deleted) (changes prefixes new-prefixes)]
          (each [_ p (ipairs added)]
            (system
             (.. "ip address add " p.prefix "::1/" p.len " dev " lan-device)))
          (each [_ p (ipairs deleted)]
            (system
             (.. "ip address del " p.prefix "::1/" p.len " dev " lan-device)))
    	  (set prefixes new-prefixes)))
    (dir:wait-events)))
