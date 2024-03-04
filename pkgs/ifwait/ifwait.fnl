(local nl (require :anoia.nl))

; (local { : view} (require :fennel))

(local { : assoc } (require :anoia))

(fn parse-args [args]
  (match args
    ["-v" & rest]  (assoc (parse-args rest) :verbose true)
    ["-t" timeout & rest] (assoc (parse-args rest) :timeout (tonumber timeout))
    [linkname "up"] {:link linkname :expecting "up"}
    [linkname "running"] {:link linkname :expecting "running"}
    [linkname "present"] {:link linkname :expecting "present"}
    [linkname nil] {:link linkname :expecting "present"}
    _  nil))

(local parameters
       (or
        (parse-args arg)
        (assert false (.. "Usage: " (. arg 0) " [-v] ifname [present|up|running]"))))

(fn run-event [v]
  (let [got
        (match v
          ;; - up: Reflects the administrative state of the interface (IFF_UP)
          ;; - running: Reflects the operational state (IFF_RUNNING).
          {:event "newlink" :name parameters.link :up :yes :running :yes}
          {:present true :up true :running true}

          {:event "newlink" :name parameters.link :up :yes}
          {:present :true :up true}

          {:event "newlink" :name parameters.link}
          {:present true }

          _
          {})]
    (when (. got parameters.expecting)
      (os.exit 0))))

(when parameters.verbose
  (print (.. (. arg 0) ": waiting for "
             parameters.link " to be " parameters.expecting)))

(each [event (nl.events {:link true})]
  (run-event event))
