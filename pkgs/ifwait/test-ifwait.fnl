(local fennel (require :fennel))

(fn event-fn [groups]
  (let [data (with-open [e (io.open "events-fixture" "r")] (e:read "*a"))
        parse (fennel.parser data)]
    (coroutine.wrap
     (fn []
       (each [ok ast parse]
         (if ok (coroutine.yield ast)))))))

(set _G.arg (doto  ["-v" "dummy0" "up"] (tset 0 "test")))

(local ifwait (require :ifwait))

(ifwait.run event-fn)
