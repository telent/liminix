(local fennel (require :fennel))

(fn event-generator [events]
  (coroutine.wrap
   (fn []
     (each [_ e (ipairs events)] (coroutine.yield e)))))

(fn file-events [path]
  (let [data (with-open [e (io.open path "r")] (e:read "*a"))
        parse (fennel.parser data)]
    (icollect [_ ast parse]
      ast)))


(set _G.arg (doto  ["-v" "dummy0" "up"] (tset 0 "test")))

(local ifwait (require :ifwait))



(ifwait.run #(event-generator (file-events "events-fixture")))
