(local { : assoc : system : dirname } (require :anoia))
(local { : mktree : rmtree : symlink } (require :anoia.fs))

(fn parse-match [s]  (string.match s "(.-)=(.+)"))

(fn parse-args [args]
  (match args
    ["-s" service & rest] (assoc (parse-args rest) :service service)
    ["-n" path & rest] (assoc (parse-args rest) :linkname path)
    matches { :matches (collect [_ m (ipairs matches)] (parse-match m)) }
    _  nil))

(fn %% [fmt ...] (string.format fmt ...))

(fn event-matches? [params e]
  (and
   e
   (accumulate [match? true
                name value (pairs params.matches)]
     (and match? (= value (. e name))))))


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

(fn run [args fh]
  (set up :unknown)
  (let [parameters
        (assert (parse-args args) (.. "can't parse args: " (table.concat args " ")))]
    (mktree (dirname parameters.linkname))
    (var finished? false)

    (while (not finished?)
      (let [e (parse-uevent (fh:read 5000))]
        (when (event-matches? parameters e)
          (let [wanted? (. {:add true :change true} e.action)]
            (toggle-service e.devname parameters.linkname parameters.service wanted?)))
        (set finished? (= e nil))
        ))))

(when (not (= (. arg 0) "test"))
  (let [nellie (require :nellie)
        netlink (nellie.open 4)]
    (run arg netlink)))

{ : run  : event-matches? }
