(local { : system : assoc : split : table= } (require :anoia))
(local svc (require :anoia.svc))
(local { : view } (require :fennel))
(local { : kill } (require :lualinux))

(fn split-paths [paths]
  (icollect [_ path (ipairs paths)]
    (split "/" path)))

(fn parse-args [args]
  (match args
    ["-r" service & rest] (assoc (parse-args rest)
                                 :controlled-service service
                                 :action :restart)
    ["-R" service & rest] (assoc (parse-args rest)
                                 :controlled-service service
                                 :action :restart-all)
    ["-s" signal service & rest] (assoc (parse-args rest)
                                        :controlled-service service
                                        :action [:signal signal])
    [watched-service & paths] { : watched-service
                                :paths (split-paths paths)
                                }))

(fn dig [tree path]
  (match path
    [el & more] (dig (. tree el) more)
    [el] (. tree el)
    [] tree))

(fn changed? [paths old-tree new-tree]
  (accumulate [changed? false
               _ path (ipairs paths)]
    (or changed? (not (table= (dig old-tree path) (dig new-tree path))))))


(fn do-action [action service]
  (case action
    :restart (system "s6-svc -r /run/service/%s" service)
    :restart-all (system "s6-rc -b -d %q; s6-rc-up-tree %q" service service)
    [:signal n] (system "s6-svc -s %d /run/service/%s" n service)))

(fn run []
  (let [{
         : controlled-service
         : action
         : watched-service
         : paths } (parse-args arg)
        dir (.. watched-service "/.outputs")
        _ (print :service-dir dir)
        service (assert (svc.open dir))]
    (print "watching " watched-service)
    (accumulate [tree (service:output ".")
                 v (service:events)]
      (let [new-tree (service:output ".")]
        (print :was (view tree) :now (view new-tree))
        (when (changed? paths tree new-tree)
          (print "watched path event:"  action controlled-service)
          (do-action action controlled-service))
        new-tree))))


{ : run }
