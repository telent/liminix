(local sock (require :minisock))
(local { : view } (require :fennel))

(fn trace [expr]
  (doto expr (print :TRACE (view expr))))

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

;; #define POLLIN          0x0001
;; #define POLLPRI         0x0002
;; #define POLLOUT         0x0004
;; #define POLLERR         0x0008
;; #define POLLHUP         0x0010
;; #define POLLNVAL        0x0020

(fn unix-socket [name]
  (let [addr (.. "\1\0"  name  "\0\0\0\0\0")
        (sock err) (sock.bind addr)]
    (assert sock err)))

(fn pollfds-for [fds]
  (table.concat (icollect [_ v (ipairs fds)] (string.pack "iHH" v 1 0))))

(fn unpack-pollfds [pollfds]
  (var i 1)
  (let [fds {}]
    (while (< i (# pollfds))
      (let [(fd _ revents i_) (string.unpack "iHH" pollfds i)]
        (if (> revents 0) (tset fds fd revents))
        (set i i_)))
    fds))

(fn parse-terms [str]
  (print :terms str)
  (collect [n (string.gmatch str "([^ ]+)")]
    (string.match n "(.-)=(.+)")))

(fn handle-client [db client]
  (match (trace (sock.read client))
    "" (do
         (db:unsubscribe client)
         false)
    s (do
        (db:subscribe
         client
         (fn [e]
           (sock.write client (view e)))
         (parse-terms s))
        true)
    (nil err) (do (print err) false)))

(fn event-loop []
  (let [fds {}]
    {
     :register #(tset fds $2 $3)
     :feed (fn [_ revents]
             (each [fd revent (pairs revents)]
               (when (not ((. fds fd) fd))
                 (tset fds fd nil)
                 (sock.close fd))))
     :fds #(icollect [fd _ (pairs fds)] fd)
    :_tbl #(do fds)                    ;exposed for tests
     }))

(fn run []
  (let [[sockname] arg
        s (unix-socket sockname)
        db (database)
        loop (event-loop)]
    (loop:register
     s
     #(match (sock.accept s)
        (client addr)
        (do
          (loop:register client (partial handle-client db))
          true)))
    (while true
      (let [pollfds (pollfds-for (loop:fds))
            (rpollfds numfds) (sock.poll pollfds 1000)]
        (when (> numfds 0)
          (loop:feed (unpack-pollfds rpollfds)))))))

{ : database : run : event-loop  }
