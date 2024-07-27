(local { : system } (require :anoia))
(local svc (require :anoia.svc))

(fn deletions [old-addresses new-addresses]
  (let [deleted {}]
    (each [n address (pairs old-addresses)]
      (let [now (. new-addresses n)]
        (if (or (not now) (not (= now.len address.len)))
            (table.insert deleted address))))
    deleted))

(fn update-addresses [wan-device addresses new-addresses exec]
  (each [_ p (ipairs (deletions addresses new-addresses))]
    (exec
     (.. "ip address del " p.address "/" p.len " dev " wan-device)))
  (each [_ p (pairs new-addresses)]
    (exec
     (.. "ip address change " p.address "/" p.len
         " dev " wan-device
         " valid_lft " p.valid
         " preferred_lft " p.preferred
         )))
  new-addresses)

(fn run []
  (let [[state-directory wan-device] arg
        dir (svc.open state-directory)]
    (accumulate [addresses []
                 v (dir:events)]
      (update-addresses wan-device addresses (or (v:output "address") []) system))))

{ : update-addresses : deletions : run }
