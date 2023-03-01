(local netlink (require :netlink))
(local sock (netlink.socket))

(when  (< (# arg) 2)
  (print "usage: waitup ifname fd")
  (os.exit 1))

(local ifname (. arg 1))
(local fd (tonumber (. arg 2)))
(local stream (io.open (.. "/proc/self/fd/" fd) "w"))

(fn notify-ready []
  (when (= "file" (io.type stream))
    (stream:write "\n")
    (stream:close))
  (print (.. (. arg 0) ": received netlink operstate up for " ifname)))


(fn run-events [evs]
  (each [_ v (ipairs evs)]
    (print :event v.event v.name)

    (match v
      ;; - up: Reflects the administrative state of the interface (IFF_UP)
      ;; - running: Reflects the operational state (IFF_RUNNING).
      {:event "newlink" :name ifname :up :yes :running :yes}
      (notify-ready)

      {:event "newlink" :name ifname :up :no}
      (os.exit 0))))

(run-events (sock:query {:link true}))

(print (.. (. arg 0) ": waiting for netlink NEWLINK " ifname))

(while (sock:poll)
  (let [ev (sock:event)]
    (run-events ev)))
