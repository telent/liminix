(local { : merge : split : file-exists? : system } (require :anoia))
(local svc (require :anoia.svc))

;; structurally this is remarkably similar to
;; acquire-lan-prefix.fnl. maybe they should be merged: if not then
;; we could at least extract some common code

;; (alternatively we could move all the parsing code into the thing in
;; the odhcp service that *writes* this stuff)

; (parse-address "2001:8b0:1111:1111:0:ffff:51bb:4cf2/128,3600,7200")


(fn parse-address [str]
  (fn parse-extra [s]
    (let [out {}]
      (each [name val (string.gmatch s ",(.-)=([^,]+)")]
        (tset out name val))
      out))
  (let [(address len preferred valid extra)
        (string.match str "(.-)/(%d+),(%d+),(%d+)(.*)$")]
    (merge {: address : len : preferred : valid} (parse-extra extra))))

(local bound-states
       { :bound true
         :rebound true
         :informed true
         :updated true
         :ra-updated true
         })

(fn changes [old-addresses new-addresses]
  (let [added {}
        deleted {}
        old-set (collect [_ v (ipairs old-addresses)] (values v true))
        new-set (collect [_ v (ipairs new-addresses)] (values v true))]
    (each [_ address (ipairs new-addresses)]
      (if (not (. old-set address))
          (table.insert added (parse-address address))))
    (each [_ address (ipairs old-addresses)]
      (if (not (. new-set address))
          (table.insert deleted (parse-address address))))
    (values added deleted)))

(let [[state-directory wan-device] arg
      dir (svc.open state-directory)]
  (var addresses [])
  (while true
    (while (not (dir:ready?)) (dir:wait))
    (if (. bound-states (dir:output "state"))
        (let [new-addresses (split " " (dir:output "/addresses"))
              (added deleted) (changes addresses new-addresses)]
          (each [_ p (ipairs added)]
            (system
             (.. "ip address add " p.address "/" p.len " dev " wan-device)))
          (each [_ p (ipairs deleted)]
            (system
             (.. "ip address del " p.address "/" p.len " dev " wan-device)))
    	  (set addresses new-addresses)))
    (dir:wait)))
