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

(set _G.arg (doto [] (tset 0 "test")))
(local ifwait (require :ifwait))

(let [gen (event-generator (file-events "events-fixture"))]
  (ifwait.run ["-v" "dummy0" "up"] #gen)
  (match (pcall gen)
    (true _) true
    (false msg) (error "didn't detect dummy0 up event")))
