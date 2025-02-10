(local { : system : join } (require :anoia))
(local svc (require :anoia.svc))
(local ll (require :lualinux))

;; ifwatch.fnl  wan:/nix/store/eee/.outputs/ifname wan:/nix/store/ffff/.outputs/ifname lan:/nix/store/abc123/.outputs/ifname

(fn parse-options [cmdline]
  (let [interfaces {}]
    (each [_ s (ipairs cmdline)]
      (let [(zone service) (string.match s "(.-):(.+)")]
        (tset interfaces (svc.open service) zone)))
    interfaces))

(local POLLIN 1)
(local POLLHUP 16)

(fn zone-contents [interfaces]
  (accumulate [zones {}
               intf zone (pairs interfaces)]
    (let [ifs (or (. zones zone) [])]
      (table.insert ifs  (intf:output "ifname"))
      (tset zones zone ifs)
      zones)))

(fn wait-for-change [interfaces]
  (let [pollfds (icollect [k _ (pairs interfaces)]
                  (bor (lshift (k:fileno) 32)
                       (lshift (bor POLLIN POLLHUP) 16)))]
    (ll.poll pollfds)))

(fn fail [msg]
  (io.stderr:write (.. "ERROR: " msg "\n")))

(macro with-popen [[handle command mode] & body]
  `(let [,handle (assert (io.popen ,command ,mode))
         val# (do ,(unpack body))]
    (case (: ,handle :close)
      ok# val#
      (nil :exit code#) (fail (.. ,command " exited "  code#))
      (nil :signal sig#) (fail (.. ,command " killed by " sig#)))))

(fn update-zone-str [zone ifnames]
  (if (> (# ifnames) 0)
      (..
       "flush set ip table-ip " zone " ; add element ip table-ip " zone " { " (table.concat ifnames ", ") " };\n"
       "flush set ip6 table-ip6 " zone " ; add element ip6 table-ip6 " zone " { " (table.concat ifnames ", ") " };\n"
       )
      (..
       "flush set ip table-ip " zone "; \n"
       "flush set ip6 table-ip6 " zone "; \n"
       )))

(fn run []
  (while true
    (let [interfaces (parse-options arg)]
      (with-popen [nft "nft -f -" :w]
        (each [zone ifnames (pairs (zone-contents interfaces))]
          (nft:write (update-zone-str zone ifnames))))
      (wait-for-change interfaces)
      (each [k _ (pairs interfaces)]
        (k:close)))))

{ :  run }
