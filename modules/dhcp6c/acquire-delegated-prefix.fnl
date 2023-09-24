(local { : system } (require :anoia))
(local svc (require :anoia.svc))

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

(fn update-prefixes [device prefixes new-prefixes]
  (let [(added deleted) (changes prefixes new-prefixes)]
    (each [_ p (ipairs added)]
      (system
       (.. "ip address add " p.address "1/" p.len " dev " device)))
    (each [_ p (ipairs deleted)]
      (system
       (.. "ip address del " p.address "1/" p.len " dev " device)))))

(fn run []
  (let [[state-directory lan-device] arg
        dir (svc.open state-directory)]
    (accumulate [addresses []
                 v (dir:events)]
      (update-prefixes lan-device addresses (v:output "prefix")))))

{ : changes : run }
