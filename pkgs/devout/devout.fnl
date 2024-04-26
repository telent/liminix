(local ll (require :lualinux))
(local {
        : AF_LOCAL
        : AF_NETLINK
        : SOCK_STREAM
        : SOCK_RAW
        : NETLINK_KOBJECT_UEVENT
        } (require :anoia.net.constants))
(local { : view } (require :fennel))

(fn trace [expr]
  (do (print :TRACE (view expr)) expr))

(macro check-errno [expr]
  (let [{ :view v } (require :fennel)]
    `(case ,expr
       val# val#
       (nil err#) (error (string.format "%s failed: errno=%d" ,(v expr) err#)))))

(fn parse-event [s]
  (let [at (string.find s "@" 1 true)
        (nl nxt) (string.find s "\0" 1 true)]
    (doto
        (collect [k v (string.gmatch
                       (string.sub s (+ 1 nxt))
                       "(%g-)=(%g+)")]
          (k:lower) v)
      (tset :path (string.sub s (+ at 1) (- nl 1))))))

(fn format-event [e]
  (..
   (string.format "%s@%s\0" e.action e.path)
   (table.concat
    (icollect [k v (pairs e)]
      (string.format "%s=%s" (string.upper k) v ))
    "\n")))


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
  (let [e (parse-event str)]
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
     :add (fn [_ event-string] (when event-string (record-event db subscribers event-string)))
     :at-path (fn [_ path] (. db path))
     :subscribe (fn [_ id callback terms]
                  (let [past-events (find-in-database db terms)]
                    (each [_ e (pairs past-events)]
                      (callback e)))
                  (tset subscribers id {: callback : terms }))
     :unsubscribe (fn [_ id] (tset subscribers id nil))
     }))

;; grepped from kernel headers

(local POLLIN          0x0001)
(local POLLPRI         0x0002)
(local POLLOUT         0x0004)
(local POLLERR         0x0008)
(local POLLHUP         0x0010)
(local POLLNVAL        0x0020)


(fn unix-socket [name]
  (let [addr (string.pack "=Hz" AF_LOCAL name)]
    (case (ll.socket AF_LOCAL SOCK_STREAM 0)
      fd (case (ll.bind fd addr)
           0 (doto fd (ll.listen 32))
           (nil err) (values nil err))
      (nil err) (values nil err))))

(fn pollfds-for [fds]
  (icollect [_ v (ipairs fds)]
    (bor (lshift v 32) (lshift 1 16))))

(fn unpack-pollfds [pollfds]
  (collect [_ v (ipairs pollfds)]
    (let [fd (band (rshift v 32) 0xffffffff)
          revent (band v 0xffff)]
      (values fd (if (> revent 0) revent nil)))))

(fn parse-terms [str]
  (print :terms str)
  (collect [n (string.gmatch (str:gsub "\n+$" "") "([^ ]+)")]
    (string.match n "(.-)=(.+)")))

(fn handle-client [db client]
  (match (ll.read client)
    "" (do
         (db:unsubscribe client)
         false)
    s (do
        (db:subscribe
         client
         (fn [e]
           (ll.write client (format-event e)))
         (parse-terms s))
        true)
    (nil err) (do (print err) false)))

(fn open-netlink [groups]
  (match (ll.socket AF_NETLINK SOCK_RAW NETLINK_KOBJECT_UEVENT)
    fd (doto fd (ll.bind (string.pack "I2I2I4I4" ; family pad pid groups
                                      AF_NETLINK 0 0 groups)))
    (nil errno) (values nil errno)))


(fn event-loop []
  (let [fds {}]
    {
     :register #(tset fds $2 $3)
     :feed (fn [_ revents]
             (each [fd revent (pairs revents)]
               (when (not ((. fds fd) fd))
                 (tset fds fd nil)
                 (ll.close fd))))
     :fds #(icollect [fd _ (pairs fds)] fd)
    :_tbl #(do fds)                    ;exposed for tests
     }))

(fn run []
  (let [[sockname nl-groups] arg
        s (check-errno (unix-socket sockname))
        db (database)
        nl (check-errno (open-netlink nl-groups))
        loop (event-loop)]
    (loop:register
     s
     #(case
       (ll.accept s)
       (client addr)
       (do
         (loop:register client (partial handle-client db))
         true)
       (nil err)
       (print (string.format "error accepting connection, errno=%d" err))))
    (loop:register
     nl
     #(do (db:add (ll.read nl)) true))
    (ll.write 10 "ready\n")
    (while true
      (let [pollfds (pollfds-for (loop:fds))]
        (ll.poll pollfds 5000)
        (loop:feed (unpack-pollfds pollfds))))))

{ : database : run : event-loop  }
