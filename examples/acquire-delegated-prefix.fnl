(local { : merge : split : file-exists? : system } (require :anoia))
(local svc (require :anoia.svc))

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
      dir (svc.open state-directory)]
  (var prefixes [])
  (while true
    (while (not (dir:ready?)) (dir:wait))
    (if (. bound-states (dir:output "state"))
        (let [new-prefixes (split " " (dir:output "/prefixes"))
              (added deleted) (changes prefixes new-prefixes)]
          (each [_ p (ipairs added)]
            (system
             (.. "ip address add " p.prefix "::1/" p.len " dev " lan-device)))
          (each [_ p (ipairs deleted)]
            (system
             (.. "ip address del " p.prefix "::1/" p.len " dev " lan-device)))
    	  (set prefixes new-prefixes)))
    (dir:wait)))
