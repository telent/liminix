(local { : view &as fennel } (require :fennel))
(local anoia (require :anoia))

(var fake-system (fn [s] (print "executing " s)))
(tset anoia :system #(fake-system $1))

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

(var succeeded? false)
(set fake-system
     (fn [s]
       (print "exec" s)
       (if (s:match "addmember") (set succeeded? true))))

(let [events
      [{:event "newlink"
        :hwaddr "b6:7d:5c:38:89:1d"
        :index 21
        :mtu 1500
        :name "dummy0"
        :running "no"
        :stamp 857161382
        :up "no"}
       {:event "newlink"
        :hwaddr "52:f0:46:da:0c:0c"
        :index 22
        :mtu 1500
        :name "dummy0"
        :running "no"
        :stamp 857161383
        :up "yes"}]
      gen (event-generator events)]
  (ifwait.run ["-v" "-s" "addmember" "dummy0" "up"] #gen)
  (assert succeeded?))
