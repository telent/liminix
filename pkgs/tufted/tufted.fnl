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

(fn merge-pathname [directory filename]
  (if (directory:match "/$")
      (.. directory  filename)
      (.. directory "/" filename)))

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
               (if eof?
                   false
                   bytes
                   (values true bytes)
                   (do
                     ;; if the file length is divisible by the block
                     ;; length, need to send an empty block at eof
                     (set eof? true)
                     (values true "")))))
           size))
        (error "host not allowed")))
  nil
  ["*"]
  69)

(os.exit))
