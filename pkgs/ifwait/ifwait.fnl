(local nl (require :anoia.nl))

; (local { : view} (require :fennel))

(local { : assoc : system } (require :anoia))

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
    (. got params.expecting)))

(fn run [args event-fn]
  (let [parameters
        (assert (parse-args args)
                (.. "Usage: ifwait [-v] ifname [present|up|running]"))]
    (when parameters.verbose
      (print (.. "ifwait: waiting for "
                 parameters.link " to be " parameters.expecting)))

    (each [e (event-fn)
           &until (event-matches? parameters e)]
      true)))

(when (not (= (. arg 0) "test"))
  (run arg #(nl.events {:link true})))

{ : run  }
