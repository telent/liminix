(local { : fork : execp : unlink } (require :posix.unistd))
(local { : wait } (require :posix.sys.wait))
(local { : mkstemp : setenv } (require :posix.stdlib))
(local { : fdopen } (require :posix.stdio))

(fn pad-file [name kb chr]
  (let [(fd out) (mkstemp "run-vm-XXXXXX")
        pad-string (string.rep (or chr "\0") 1024)]
    (with-open [f (fdopen fd :w)]
      (for [i 1 kb] (f:write pad-string))
      (f:seek :set 0)
      (with-open [input (assert (io.open name :rb))]
        (f:write (input:read "*a")))
      (f:seek :end 0))
    out))

(fn spawn [command args]
  (match (fork)
    (nil msg) (error (.. "couldn't fork: " msg))
    0 (execp command args)
    pid (wait pid)))

(fn appendm [t2 t1]
  (table.move t1 1 (# t1) (+ 1 (# t2)) t2)
  t2)

(fn merge [table1 table2]
  (collect [k v (pairs table2) &into table1]
    k v))

(fn assoc [tbl k v]
  (tset tbl k v)
  tbl)

(fn parse-args [args]
  (match args
    ["--background" dir & rest] (assoc (parse-args rest) :background dir)
    ["--u-boot" bin & rest]
    (assoc (parse-args rest) :u-boot (pad-file bin (* 4 1024) "\xff"))
    ["--arch" arch & rest] (assoc (parse-args rest) :arch arch)
    ["--phram-address" addr & rest] (assoc (parse-args rest) :phram-address addr)
    ["--lan" spec & rest] (assoc (parse-args rest) :lan spec)
    ["--command-line" cmd & rest] (assoc (parse-args rest) :command-line cmd)
    [kernel rootfsimg]
    { :kernel kernel :rootfs (pad-file rootfsimg (* 16 1024)) }
    ))

(local options
       (assert
        (merge { :arch "mips" } (parse-args arg))
        (.. "Usage: " (. arg 0) " blah bah")))

(fn background [dir]
  (let [pid (.. dir "/pid")
        sock (.. dir "/console")
        monitor (.. dir "/monitor")]
    ["--daemonize"
     "--pidfile" pid
     "-serial" (.. "unix:" sock ",server,nowait")
     "-monitor" (.. "unix:" monitor ",server,nowait")]))

(fn access-net []
  [
   "-netdev" "socket,id=access,mcast=230.0.0.1:1234,localaddr=127.0.0.1"
   "-device" "virtio-net,disable-legacy=on,disable-modern=off,netdev=access,mac=ba:ad:1d:ea:21:02"
   ])

(fn local-net [override]
  [
   "-netdev" (.. (or override "socket,mcast=230.0.0.1:1235,localaddr=127.0.0.1")
                 ",id=lan")
   "-device" "virtio-net,disable-legacy=on,disable-modern=off,netdev=lan,mac=ba:ad:1d:ea:21:01"
   ])


(fn bootable [cmdline uboot]
  (if uboot
      ["-drive" (.. "if=pflash,format=raw,file=" uboot )]
      (let [cmdline (.. cmdline " liminix mtdparts=phram0:16M(rootfs) phram.phram=phram0," options.phram-address ",16Mi,65536 root=/dev/mtdblock0")]
        ["-kernel" options.kernel "-append" cmdline])))

(local bin {
            :mips ["qemu-system-mips" "-M" "malta"]
            :aarch64 ["qemu-system-aarch64" "-M" "virt"
                      "-semihosting" "-cpu" "cortex-a72"]
            :arm ["qemu-system-arm" "-M" "virt,highmem=off"
                  "-cpu" "cortex-a15"]
            })

(local exec-args
       (-> []
           (appendm (. bin options.arch))
           (appendm ["-m" "272"
                     "-echr" "16"
                     "-device"
                     (.. "loader,file=" options.rootfs ",addr=" options.phram-address)

                     ])
           (appendm
            (if options.background
                (background options.background)
                ["-serial" "mon:stdio"]))
           (appendm (bootable (or options.command-line "") options.u-boot))
           (appendm (access-net))
           (appendm (local-net options.lan))
           (appendm ["-display" "none"])))

(match exec-args
  [cmd & params] (print  (spawn cmd params)))

(if options.rootfs (unlink options.rootfs))
(if options.u-boot (unlink options.u-boot))
