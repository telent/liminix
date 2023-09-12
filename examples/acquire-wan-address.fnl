(local { : system } (require :anoia))
(local svc (require :anoia.svc))

(local bound-states
       { :bound true
         :rebound true
         :informed true
         :updated true
         :ra-updated true
         })

(fn changes [old-addresses new-addresses]
  (let [added {}
        deleted {}]
    (each [n address (pairs new-addresses)]
      (if (not (. old-addresses n))
          (table.insert added address)))
    (each [n address (pairs old-addresses)]
      (if (not (. new-addresses n))
          (table.insert deleted address)))
    (values added deleted)))

(fn update-addresses [wan-device addresses new-addresses]
  (let [(added deleted) (changes addresses new-addresses)]
    (each [_ p (ipairs added)]
      (system
       (.. "ip address add " p.address "/" p.len " dev " wan-device)))
    (each [_ p (ipairs deleted)]
      (system
       (.. "ip address del " p.address "/" p.len " dev " wan-device)))
    new-addresses))

(fn run []
  (let [[state-directory wan-device] arg
        dir (svc.open state-directory)]
    (accumulate [addresses []
                 v (dir:events)]
      ;; we don't handle unbound or stopped, where we should
      ;; take the addresses away
      (when (. bound-states (v:output "state"))
        (update-addresses wan-device addresses (v:output "address"))))))

{ : update-addresses : changes : run }
