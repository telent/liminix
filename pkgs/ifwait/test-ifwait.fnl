(local { : view &as fennel } (require :fennel))
(local anoia (require :anoia))
(import-macros { : expect= } :anoia.assert)

;; nix-shell --run "cd pkgs/ifwait && fennelrepl test-ifwait.fnl"

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
  (ifwait.run ["dummy0" "up"] #gen)
  (match (pcall gen)
    (true _) true
    (false msg) (error "didn't detect dummy0 up event")))

(var upsies [])
(set fake-system
     (fn [s]
       (if (s:match "-u change addmember")
           (table.insert upsies :u)
           (s:match "-d change addmember")
           (table.insert upsies :d))))

(fn newlink [name up running]
  {:event "newlink"
   :hwaddr "b6:7d:5c:38:89:1d"
   :index (string.unpack ">i2" name)
   :mtu 1500
   : name
   : running
   :stamp 857161382
   : up })

"when it gets events that don't match the interface, nothing happens"

(let [gen (-> [(newlink "eth1" "no" "no")] event-generator)]
  (set upsies [])
  (ifwait.run [ "-s" "addmember" "dummy0" "up"] #gen)
  (expect= upsies []))

"when it gets an event that should start the service, the service starts"

(let [gen (->
           [(newlink "dummy0" "no" "no")
            (newlink "dummy0" "yes" "no")
            (newlink "eth1" "no" "no")]
           event-generator)]
  (set upsies [])
  (ifwait.run ["-s" "addmember" "dummy0" "up"] #gen)
  (expect= upsies [:d :u]))

"when it gets an event that should stop the service, the service stops"

(let [gen (->
           [(newlink "dummy0" "no" "no")
            (newlink "dummy0" "yes" "no")
            (newlink "dummy0" "no" "no")
            ]
           event-generator)]
  (set upsies [])
  (ifwait.run ["-s" "addmember" "dummy0" "up"] #gen)
  (expect= upsies [:d :u :d]))

"it does not call s6-rc again if the service is already in required state"

(let [gen (->
           [(newlink "dummy0" "no" "no")
            (newlink "dummy0" "yes" "no")
            (newlink "dummy0" "yes" "yes")
            (newlink "dummy0" "yes" "yes")
            (newlink "dummy0" "yes" "no")
            (newlink "dummy0" "no" "no")
            ]
           event-generator)]
  (set upsies [])
  (ifwait.run ["-s" "addmember" "dummy0" "up"] #gen)
  (expect= upsies [:d :u :d]))

"it handles an error return from s6-rc"

(set fake-system
     (fn [s]
       (if (s:match "-u change addmember")
           (table.insert upsies :u)
           (s:match "-d change addmember")
           (table.insert upsies :d))
       (error "false")
       ))

(let [gen (->
           [(newlink "dummy0" "yes" "no")
            (newlink "dummy0" "yes" "yes")
            (newlink "dummy0" "yes" "yes")
            (newlink "dummy0" "yes" "no")
            (newlink "dummy0" "no" "no")
            ]
           event-generator)]
  (set upsies [])
  (ifwait.run ["-s" "addmember" "dummy0" "up"] #gen)
  (expect= upsies [:u :u :u :u]))

(print "OK")
