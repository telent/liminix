(local nl (require :anoia.nl))
(local { : assoc : system } (require :anoia))

; (local { : view} (require :fennel))

(fn parse-args [args]
  (match args
    ["-v" & rest]  (assoc (parse-args rest) :verbose true)
    ["-t" timeout & rest] (assoc (parse-args rest) :timeout (tonumber timeout))
    ["-s" service & rest] (assoc (parse-args rest) :service service)
    [linkname "up"] {:link linkname :expecting "up"}
    [linkname "running"] {:link linkname :expecting "running"}
    [linkname "present"] {:link linkname :expecting "present"}
    [linkname nil] {:link linkname :expecting "present"}
    _  nil))

(fn event-matches? [params v]
  (let [got
        (match v
          ;; - up: Reflects the administrative state of the interface (IFF_UP)
          ;; - running: Reflects the operational state (IFF_RUNNING).
          {:event "newlink" :name params.link :up :yes :running :yes}
          {:present true :up true :running true}

          {:event "newlink" :name params.link :up :yes}
          {:present :true :up true}

          {:event "newlink" :name params.link}
          {:present true }

          _
          {})]
    (not (not (. got params.expecting)))))

(var up :unknown)
(fn toggle-service [service wanted?]
  (when (not (= up wanted?))
    (set up
         (if wanted?
             (pcall system (.. "s6-rc -b -u change " service))
             (not (pcall system (.. "s6-rc -b -d change " service)))))
    ))

(fn run [args event-fn]
  (set up :unknown)
  (let [parameters
        (assert (parse-args args)
                (.. "Usage: ifwait [-v] ifname [present|up|running]"))]
    (when parameters.verbose
      (print (.. "ifwait: waiting for "
                 parameters.link " to be " parameters.expecting)))

    (if parameters.service
        (each [e (event-fn)]
          (if (= e.name parameters.link)
              (toggle-service parameters.service (event-matches? parameters e))))
        (each [e (event-fn)
               &until (event-matches? parameters e)]
          true))))

(when (not (= (. arg 0) "test"))
  (run arg #(nl.events {:link true})))

{ : run  }
