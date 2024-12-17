(local tftp (require :tftp))
(local { : realpath} (require :posix.stdlib))
(local { : view } (require :fennel))

(local options
       (match arg
         ["-a" ip-address dir]
         { :allow ip-address :base-directory (realpath dir)}

         [dir]
         { :allow nil :base-directory (realpath dir)}

         []
         (error "missing command line parameters")
         ))

(print (.. "TFTP serving from " options.base-directory))

;; this is a copy of anoia append-path
(fn  merge-pathname [dirname filename]
  (let [base (or (string.match dirname "(.*)/$") dirname)
        result []]
    (each [component (string.gmatch filename "([^/]+)")]
      (if (and (= component "..") (> (# result) 0))
          (table.remove result)
          (= component "..")
          (error "path traversal attempt")
          true
          (table.insert result component)))
    (.. base "/" (table.concat result "/"))))

(->
 (tftp:listen
  (fn [file host port]
    (if (or (not options.allow) (= host options.allow))
        (let [pathname (merge-pathname options.base-directory file)
              f (io.open pathname "rb")
              size (f:seek "end")]
          (f:seek "set" 0)
          (var eof? false)
          (values
           (fn handler [reqlen]
             (let [bytes (f:read reqlen)]
               (if bytes
                   (values true bytes)
                   (values false nil))))
           size))
        (error "host not allowed")))
  nil
  ["*"]
  69)

(os.exit))
