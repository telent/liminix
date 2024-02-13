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
    ;; if some address has changed (e.g. preferred/valid lifetime)
    ;; then we don't want to delete it before re-adding it because
    ;; the kernel will drop any routes that go through it. On the
    ;; other hand, we can't add it _before_ deleting it as we'll
    ;; get an error that it already exists. Therefore, use "change"
    ;; instead of "add", it works a bit more like an upsert
    (each [_ p (ipairs added)]
      (system
       (.. "ip address change " p.address "1/" p.len " dev " device
           " valid_lft " p.valid
           " preferred_lft " p.preferred
           )))
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
