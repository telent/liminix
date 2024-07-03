(local { : opendir : readdir } (require :lualinux))
(local { : view } (require :fennel))

(fn fail [err]
  (print "ERROR" err)
  (os.exit 1))

(macro with-popen [[handle command] & body]
  `(let [,handle (assert (io.popen ,command))
         val# (do ,(unpack body))]
    (case (: ,handle :close)
      ok# val#
      (nil :exit code#) (fail (.. ,command " exited "  code#))
      (nil :signal sig#) (fail (.. ,command " killed by " sig#)))))

(fn popen [command]
  (with-popen [fh command] (icollect [v (fh:lines)] v)))

(fn controlled-services [dir]
  (case (opendir dir)   ;; FIXME [nit] doesn't closedir
    d (collect [filename #(readdir d)]
        (if (not (string.match filename "^%."))
            (values filename filename)))
    (nil err) (fail (.. "can't open " dir " :" err))))

(fn stopped-services []
  (popen (.. "s6-rc -da list")))

(fn stopped-controlled-services [dir]
  (let [controlled (controlled-services dir)]
    (with-popen [h (.. "s6-rc -da list")]
      (collect [s (h:lines)]
        (if (. controlled s) (values s s))))))

(fn dependencies [service]
  (popen (.. "s6-rc-db all-dependencies " service)))

(fn reverse-dependencies [service]
  (popen (.. "s6-rc-db -d all-dependencies " service)))

(fn start-service [name]
  (case (os.execute (.. "s6-rc -u change " name))
    (ok) nil
    (nil err) (fail err)))

(fn run [dir]
  (let [service (. arg 1)
        blocks (stopped-controlled-services (or dir "/run/services/controlled"))]
    (print :service service :blocks (view blocks))
    (each [_ s (ipairs (reverse-dependencies service))]
      (print :dep s)
      (when
          (accumulate [start true
                       _ dep (ipairs (dependencies s))]
            (and start (or (= s service) (not (. blocks dep)))))
        (start-service s)))))

{ : run }
