(local fennel (require :fennel))

(fn events [groups]
  (let [data (with-open [e (io.open "events-fixture" "r")] (e:read "*a"))
        parse (fennel.parser data)]
    ;(print data)
    (coroutine.wrap
     (fn []
       (each [ok ast parse]
         (if ok (coroutine.yield ast)))))))

(tset package.loaded :anoia.nl { :events events })

(set _G.arg (doto  ["-v" "dummy0" "up"] (tset 0 "ifwait")))

(fennel.dofile "ifwait.fnl" { :correlate true })
