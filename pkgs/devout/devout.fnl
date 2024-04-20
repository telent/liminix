(fn parse-uevent [s]
  (let [at (string.find s "@" 1 true)
        (nl nxt) (string.find s "\0" 1 true)]
    (doto
        (collect [k v (string.gmatch
                       (string.sub s (+ 1 nxt))
                       "(%g-)=(%g+)")]
          (k:lower) v)
      (tset :path (string.sub s (+ at 1) (- nl 1))))))

(fn event-matches? [e terms]
  (accumulate [match? true
               name value (pairs terms)]
    (and match? (= value (. e name)))))

(fn find-in-database [db terms]
  (accumulate [found []
               _ e (pairs db)]
    (if (event-matches? e terms)
        (doto found (table.insert e))
        found)))

(fn database []
  (let [db {}]
    {
     :find (fn [_ terms] (find-in-database db terms))
     :add (fn [_ event-string]
            (let [e (parse-uevent event-string)]
              (tset db e.path e)))
     :at-path (fn [_ path] (. db path))
     }))


{ : database }
