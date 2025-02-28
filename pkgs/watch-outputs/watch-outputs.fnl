(local { : %% : system : assoc : split : table= : dig } (require :anoia))
(local svc (require :anoia.svc))
(local { : kill &as ll} (require :lualinux))
(import-macros { : define-tests : expect : expect= } :anoia.assert)

(local { : view } (require :fennel))

(fn output-refs [outputs]
  (let [result {}]
    (each [_ v (ipairs outputs)]
      (let [[service path] (split ":" v)
            paths (or (. result service) [])]
        (table.insert paths (split "/" path ))
        (tset result service paths)))
    result))

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
    outputs { :output-references (output-refs outputs) } ))

(define-tests
  (expect= (parse-args ["-r" "daemon"
                        "/nix/store/s1:out1"
                        "/nix/store/s2:out1" "/nix/store/s2:out2/ifname"])
           {:action "restart"
            :controlled-service "daemon"
            :output-references
            {"/nix/store/s1" [["out1"]]
             "/nix/store/s2" [["out1"] ["out2" "ifname"]]}}
           ))


(fn changed? [paths old-tree new-tree]
  (accumulate [changed? false
               _ path (ipairs paths)]
    (or changed? (not (table= (dig old-tree path) (dig new-tree path))))))

(define-tests
  (expect (changed? [["ifname"]] {:ifname "true"} {:ifindex 2}))
  (expect (changed? [["ifname"]] {:ifname "true"} {:ifname "false"}))
  (expect (not (changed? [["ifname"]] {:ifname "true"} {:ifname "true"})))
  (expect (not (changed? [["mtu"]] {:ifname "true"} {:ifname "false"})))
  (expect (not (changed? [["mtu"]] {:ifname "true"} {:ifname "false"})))
  )



(fn do-action [action service]
  (case action
    :restart (system (%% "s6-svc -r /run/service/%s" service))
    :restart-all (system (%% "s6-rc -b -d %q; s6-rc-up-tree %q" service service))
    [:signal n] (system (%% "s6-svc -s %d /run/service/%s" n service))))

(local POLLIN  0x0001)
(local POLLHUP 0x0010)

(fn wait-for-change [services]
  (let [pollfds (collect [s _p (ipairs services)]
                  (bor (lshift (s:fileno) 32)
                       (lshift (bor POLLIN POLLHUP) 16)))]
    (ll.poll pollfds)))

(fn open-services [output-references]
  (collect [s p (pairs output-references)]
    (values (assert (svc.open (.. s "/.outputs"))) p)))

(fn run []
  (let [trees {}
        {
         : output-references
         : controlled-service
         : action
         : watched-service
         : paths } (parse-args arg)]
    (while true
      (let [services (open-services output-references)
            trees (collect [s _ (pairs services)]
                    (values s (s:output ".")))]
        (wait-for-change services)
        (each [service paths (pairs services)]
          (let [new-tree (service:output ".")]
            (when (changed? paths (. trees service) new-tree)
              (print "watched path event:"  action controlled-service)
              (do-action action controlled-service))))))))



{ : run }
