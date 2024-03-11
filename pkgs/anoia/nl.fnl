(local netlink (require :netlink))

; (local { : view } (require :fennel))

(fn events [groups]
  (let [sock (netlink.socket)]
    (coroutine.wrap
     (fn []
       (each [_ e (ipairs (sock:query groups))]
         (coroutine.yield e))
       (while (sock:poll)
         (each [_ e (ipairs (sock:event))]
           (coroutine.yield e)))))))

{ : events }
