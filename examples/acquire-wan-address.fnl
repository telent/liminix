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

(fn run [state-directory wan-device]
  (let [dir (svc.open state-directory)]
    (var addresses [])
    (while true
      (while (not (dir:ready?)) (dir:wait))
      (when (. bound-states (dir:output "state"))
        (set addresses
             (update-addresses wan-device addresses (dir:output "address"))))
      (dir:wait))))


(if (os.getenv "RUN_TESTS")
    { : update-addresses : changes : run }
    (let [[state-directory wan-device] arg]
      (run state-directory wan-device)))
