(local { : assoc : system : dirname } (require :anoia))
(local { : mktree : rmtree : symlink } (require :anoia.fs))
(local { : AF_LOCAL : SOCK_STREAM } (require :anoia.net.constants))
(local ll (require :lualinux))

(local { : view } (require :fennel))

(fn parse-args [args]
  (match args
    ["-s" service & rest] (assoc (parse-args rest) :service service)
    ["-n" path & rest] (assoc (parse-args rest) :linkname path)
    matches { :matches (table.concat matches " ") }
    _  nil))

(fn %% [fmt ...] (string.format fmt ...))

(var up :unknown)

(fn start-service [devname linkname service]
  (match (symlink (.. "/dev/" devname ) linkname)
    ok (pcall system (%% "s6-rc -b -u change %q" service))
    (nil err) false))

(fn stop-service [linkname service]
  (match (pcall system (%% "s6-rc -b -d change %q" linkname service))
    ok (os.remove linkname)
    (nil err) false))

(fn toggle-service [devname linkname service wanted?]
  (when (not (= up wanted?))
    (set up
         (if wanted?
             (start-service devname linkname service)
             (not (stop-service linkname service))))))

(fn parse-uevent [s]
  (when s
    (let [(nl nxt) (string.find s "\0" 1 true)]
      (collect [k v (string.gmatch
                     (string.sub s (+ 1 nxt))
                     "(%g-)=(%g+)")]
        (k:lower) v))))

(fn run-with-fh [fh args]
  (set up :unknown)
  (let [parameters
        (assert (parse-args args) (.. "can't parse args: " (table.concat args " ")))]
    (mktree (dirname parameters.linkname))
    (var finished? false)

    (print "registering for events" (fh:write parameters.matches))

    (while (not finished?)
      (let [e (parse-uevent (fh:read))]
        (when e
          (let [wanted? (. {:add true :change true} e.action)]
            (toggle-service e.devname parameters.linkname parameters.service wanted?)))
        (set finished? (= e nil))
        ))))

(fn unix-connect [pathname]
  (let [addr (string.pack "=Hz" AF_LOCAL pathname)]
    (match (ll.socket AF_LOCAL SOCK_STREAM 0)
      sock (doto sock (ll.connect addr))
      (nil err) (error err))))


(fn run [args]
  (let [fd (assert (unix-connect "/run/devout.sock"))
        devout {
                :read #(ll.read fd)
                :write #(ll.write fd $2)
                :close #(ll.close fd)
                }]
    (run-with-fh devout arg)))

{ : run : run-with-fh  }
