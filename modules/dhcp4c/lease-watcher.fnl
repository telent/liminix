(local { : %% : system } (require :anoia))
(local svc (require :anoia.svc))

(fn up-service [name]
  (system (%% "s6-rc-up-tree %q" name)))

(fn down-service [name]
  (system (%% "s6-rc -b -d change %q" name)))

(fn react [s controlled]
  (let [ip (s:output "ip")]
    (print "event" "ip=" ip)
    (if ip
        (up-service controlled)
        (down-service controlled))))

(fn run []
  (let [[watched controlled] arg
        s (assert (svc.open watched))]
    (print :service s)
    (react s controlled)
    (each [e (s:events)]
      (print :event e)
      (react s controlled))))

{ : run }
