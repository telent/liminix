(local { : view } (require :fennel))
(import-macros { : expect= } :anoia.assert)

(fn parse-uevent [s]
  (let [(nl nxt) (string.find s "\0" 1 true)]
    (doto
        (collect [k v (string.gmatch
                       (string.sub s (+ 1 nxt))
                       "(%g-)=(%g+)")]
          (k:lower) v)
      (tset :path (string.sub s 1 (- nl 1))))))

(fn database []
  (let [db {}]
    {
     :find (fn [_ terms] [(.  db (next db))])
     :add (fn [_ event-string]
            (let [e (parse-uevent event-string)]
              (tset db e.path e)))
     }))

(macro example [description & body]
  `(do ,body))

(example
 "given an empty database, search for some criteria matches no entries"
 (let [db (database)]
   (expect= (db:find {:partname "boot"}) [])))

(example
 "when I add a device, I can find it"
 (let [db (database)]
   (db:add "add@/devices/pci0000:00/0000:00:13.0/usb1/1-1/1-1:1.0/host0/target0:0:0/0:0:0:0/block/sda\0ACTION=add
DEVPATH=/devices/pci0000:00/0000:00:13.0/usb1/1-1/1-1:1.0/host0/target0:0:0/0:0:0:0/block/sda
SUBSYSTEM=block
MAJOR=8
MINOR=0
DEVNAME=sda
DEVTYPE=disk
DISKSEQ=2
SEQNUM=1527")
   (let [[m & more] (db:find {:devname "boot"})]
     (expect= m.devname "sda")
     (expect= m.major "8")
     (expect= more []))))



(print "OK")
