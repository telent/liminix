(local { : opendir : readdir } (require :lualinux))

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

(fn stopped-controlled-services [dir]
  (let [controlled (controlled-services dir)]
    (with-popen [h (.. "s6-rc -b -da list")]
      (collect [s (h:lines)]
        (if (. controlled s) (values s s))))))

(fn dependencies [service]
  (popen (.. "s6-rc-db all-dependencies " service)))

(fn reverse-dependencies [service]
  (popen (.. "s6-rc-db -d all-dependencies " service)))

(fn start-service [name]
  (with-popen [h (.. "s6-rc -b -u change " name)]
    (print (h:read "*a"))))

(fn keys [t]
  (icollect [_ v (pairs t)] v))

(fn run [dir]
  (let [service (. arg 1)
        blocks (doto
                   (stopped-controlled-services (or dir "/run/services/controlled"))
                 (tset service nil))
        rdepends (reverse-dependencies service)
        starts
        (icollect [_ s (ipairs rdepends)]
          (when
              (accumulate [start true
                           _ dep (ipairs (dependencies s))]
                (and start (not (. blocks dep))))
            s))]
    (print "s6-rc-up-tree"
           service
           "blocks (" (table.concat (keys blocks) ", ") ")"
           ;; "rdepends (" (table.concat rdepends ", ") ")"
           "start (" (table.concat  starts ", ") ")")
    (if (> (# starts) 0)
        (each [_ s (ipairs starts)]
          (start-service s))
        (os.exit 1))))


{ : run }
