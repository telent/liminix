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

(fn record-event [db subscribers str]
  (let [e (parse-uevent str)]
    (match e.action
      :add (tset db e.path e)
      :change (tset db e.path e)
      ;; should we do something for bind?
      :remove (tset db e.path nil)
      )
    (each [_ { : terms : callback } (pairs subscribers)]
      (if (event-matches? e terms) (callback e)))
    e))

(fn database []
  (let [db {}
        subscribers []]
    {
     :find (fn [_ terms] (find-in-database db terms))
     :add (fn [_ event-string] (record-event db subscribers event-string))
     :at-path (fn [_ path] (. db path))
     :subscribe (fn [_ id callback terms]
                  (tset subscribers id {: callback : terms }))
     :unsubscribe (fn [_ id] (tset subscribers id nil))

     }))


{ : database }
