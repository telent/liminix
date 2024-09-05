(local { : dirname : merge } (require :anoia))
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

(fn format-event [e]
  (..
   (string.format "%s@%s\0" e.action e.path)
   (table.concat
    (icollect [k v (pairs e.properties)]
      (string.format "%s=%s" (string.upper k) v ))
    "\n")))

(fn attrs-match? [event expected]
  (accumulate [match? true
               name value (pairs expected)]
    (and match? (= value (event:attr name)))))

(fn ancestor-attrs-match? [event expected]
  (accumulate [match? true
               name value (pairs expected)]
    (and match? (= value (event:ancestor-attr name)))))

(fn event-matches? [e terms]
  (accumulate [match? true
               name value (pairs terms)]
    (and match?
         (case name
           :attr (attrs-match? e value)
           :attrs (ancestor-attrs-match? e value)
           other (= value (. e.properties name))))))

(fn read-if-exists [pathname]
  (match (ll.open pathname 0 0)
    fd (let [s (ll.read fd 4096)
             s1 (string.gsub s "[ \n]*(.-)[ \n]*" "%1")]
         (ll.close fd)
         s1)
    nil nil))

(fn event-ancestor-attr [event name]
  (fn walk-up [sys-path path name]
    (when path
      (or (read-if-exists (.. sys-path "/" path "/" name))
          (walk-up sys-path (dirname path) name))))
  (walk-up event.sys-path event.path name))

(fn event-attr [event name]
  (read-if-exists (..  event.sys-path "/" event.path "/" name)))

(fn parse-event [s]
  (let [at (string.find s "@" 1 true)
        (nl nxt) (string.find s "\0" 1 true)
        properties
        (collect [k v (string.gmatch
                       (string.sub s (+ 1 nxt))
                       "(%g-)=(%g+)")]
          (k:lower) v)]
    { : properties
      :path (string.sub s (+ at 1) (- nl 1))
      :action (string.sub s 1 (- at 1))
      :format format-event
      :matches? event-matches?
      :attr event-attr
      :ancestor-attr event-ancestor-attr
      }))

(fn find-in-database [db terms]
  (accumulate [found []
               _ e (pairs db)]
    (if (e:matches? terms)
        (doto found (table.insert e))
        found)))

(fn record-event [db subscribers e]
  (match e.action
    :add (tset db e.path e)
    :change (tset db e.path e)
    ;; should we do something for bind?
    :remove (tset db e.path nil)
    )
  (each [_ { : terms : callback } (pairs subscribers)]
    (if (e:matches? terms) (callback e)))
  e)

(fn database [options]
  (let [db {}
        subscribers []
        { : sys-path } (or options {:sys-path "/sys" })]
    {
     :find (fn [_ terms] (find-in-database db terms))
     :add (fn [_ event-string]
            (when event-string
              (let [e (doto (parse-event event-string)
                        (tset :sys-path sys-path))]
                (record-event db subscribers e))))
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
  (let [addr (string.pack "=Hz" AF_LOCAL name)
        fd (check-errno (ll.socket AF_LOCAL SOCK_STREAM 0))]
    (os.remove name)
    (check-errno (ll.bind fd addr))
    (check-errno (ll.listen fd 32))
    fd))

(fn pollfds-for [fds]
  (icollect [_ v (ipairs fds)]
    (bor (lshift v 32) (lshift 1 16))))

(fn unpack-pollfds [pollfds]
  (collect [_ v (ipairs pollfds)]
    (let [fd (band (rshift v 32) 0xffffffff)
          revent (band v 0xffff)]
      (values fd (if (> revent 0) revent nil)))))

(fn parse-terms [str]
  (let [keys {}
        attr {}
        attrs {}]
    (each [term (string.gmatch (str:gsub "\n+$" "") "([^ ]+)")]
      (let [(k v) (string.match term "(.-)=(.+)")]
        (match (string.match k "(.+)%.(.+)")
          ("attrs" a) (tset attrs a v)
          ("attr" a) (tset attr a v)
          nil (tset keys k v))))
    (merge keys {: attr : attrs})))

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
  (let [fd (check-errno (ll.socket AF_NETLINK SOCK_RAW NETLINK_KOBJECT_UEVENT))]
    (check-errno (ll.bind fd (string.pack "I2I2I4I4" ; family pad pid groups
                                          AF_NETLINK 0 0 groups)))
    fd))

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

{ : database : run : event-loop : parse-event

  : parse-terms
  }
