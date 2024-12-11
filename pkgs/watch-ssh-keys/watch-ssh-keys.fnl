(local { : system : assoc : split : dup : table= : dig : append-path } (require :anoia))
(local svc (require :anoia.svc))
(import-macros { :  define-tests : expect : expect= } :anoia.assert)

(fn parse-args [args]
  (match args
    ["-d" path & rest] (assoc (parse-args rest)
                              :out-path path)
    [watched-service path] { : watched-service
                             : path }))

(fn write-changes [path old-tree new-tree]
  (when (not (table= old-tree new-tree))
    (io.stderr:write "new ssh keys\n")
    (each [username pubkeys (pairs new-tree)]
      (with-open [f (assert (io.open (append-path path username) :w))]
        ;;  the keys are "1" "2" "3" etc, so pairs not ipairs
        (each [_ k (pairs pubkeys)]
          (f:write k)
          (f:write "\n")))))
  (each [k v (pairs old-tree)]
    (when (not (. new-tree k))
      (os.remove (append-path path k))))
  new-tree)

(define-tests
  (local { : file-exists? } (require :anoia))
  (print "running tests")
  (let [tree {
              "dan" ["f1" "f2"]
              "root" ["f1"]
              }
        out-dir (: (assert (io.popen "mktemp -d -p '' fennel-XXXXXXX" :r))  :read "l")]
    ;; if the trees are identical, nothing is written
    (write-changes out-dir tree tree)
    (expect (not (file-exists? (.. out-dir "/dan"))))

    ;; add an entry
    (write-changes out-dir tree (assoc (dup tree) "geoffrey" ["rr"]))
    (expect (file-exists? (.. out-dir "/dan")))
    (expect= (with-open [f (io.open (.. out-dir "/geoffrey"))] (f:read "*a")) "rr\n")

    ;; newly-missing entries are removed
    (write-changes out-dir (assoc (dup tree) "geoffrey" ["rr"]) tree)
    (expect (not (file-exists? (.. out-dir "/geoffrey"))))

    (write-changes out-dir tree {})
    (os.remove out-dir)
    ))

(fn run []
  (let [{: out-path : watched-service : path } (parse-args arg)
        dir (.. watched-service "/.outputs")
        service (assert (svc.open dir))]
    (accumulate [tree {}
                 v (service:events)]
      (write-changes out-path tree (or (service:output path) {})))))


{ : run }
