(local { : database : event-loop : parse-event : parse-terms } (require :devout))
(local { : view } (require :fennel))
(local ll (require :lualinux))
(import-macros { : expect : expect= } :anoia.assert)

(var failed false)
(fn fail [d msg] (set failed true) (print :FAIL d (.. "\n" msg)))

(macro example [description & body]
  (if (. body 1)
      `(let [(ok?# err#) (xpcall (fn [] ,body) debug.traceback)]
         (if ok?#
             (print :PASS ,description)
             (fail ,description err#)))
      `(print :PENDING ,description)))

(local sda-uevent
       "add@/devices/pci0000:00/0000:00:13.0/usb1/1-1/1-1:1.0/host0/target0:0:0/0:0:0:0/block/sda\0ACTION=add
DEVPATH=/devices/pci0000:00/0000:00:13.0/usb1/1-1/1-1:1.0/host0/target0:0:0/0:0:0:0/block/sda
SUBSYSTEM=block
MAJOR=8
MINOR=0
DEVNAME=sda
DEVTYPE=disk
DISKSEQ=2
SEQNUM=1527")

(local sdb1-insert
       "add@/devices/pci0000:00/0000:00:14.0/usb1/1-3/1-3:1.0/host1/target1:0:0/1:0:0:0/block/sdb/sdb1\0ACTION=add
DEVPATH=/devices/pci0000:00/0000:00:14.0/usb1/1-3/1-3:1.0/host1/target1:0:0/1:0:0:0/block/sdb/sdb1
SUBSYSTEM=block
DEVNAME=/dev/sdb1
DEVTYPE=partition
DISKSEQ=33
PARTN=1
SEQNUM=82381
MAJOR=8
MINOR=17")

(local sdb1-remove
       "remove@/devices/pci0000:00/0000:00:14.0/usb1/1-3/1-3:1.0/host1/target1:0:0/1:0:0:0/block/sdb/sdb1\0ACTION=remove
DEVPATH=/devices/pci0000:00/0000:00:14.0/usb1/1-3/1-3:1.0/host1/target1:0:0/1:0:0:0/block/sdb/sdb1
SUBSYSTEM=block
DEVNAME=/dev/sdb1
DEVTYPE=partition
DISKSEQ=33
PARTN=1
SEQNUM=82386
MAJOR=8
MINOR=17")

(example
 "I can parse an event"
 (let [e (parse-event sdb1-insert)]
   (expect= e.properties.seqnum "82381")
   (expect= e.properties.devname "/dev/sdb1")
   (expect= e.path "/devices/pci0000:00/0000:00:14.0/usb1/1-3/1-3:1.0/host1/target1:0:0/1:0:0:0/block/sdb/sdb1")
   (expect= e.action :add)
   (expect= e (parse-event (e:format)))))

(example
 "An event can match against terms"
 (let [terms {:devname "foo" :partname "my-usbstick"}]
   (expect= (: (parse-event "add@/\0SEQNUM=1") :matches? terms) false)
   (expect= (: (parse-event "add@/\0DEVNAME=bill") :matches? terms) false)
   (expect= (: (parse-event "add@/\0DEVNAME=foo\nPARTNAME=my-usbstick") :matches? terms) true)
   (expect= (: (parse-event "add@/\0DEVNAME=foo\nPARTNAME=my-usbstick\nOTHERTHING=bar") :matches? terms) true)
   ))

(example
 "given an empty database, searching it finds no entries"
 (let [db (database)]
   (expect= (db:find {:partname "boot"}) [])))

(example
 "when I add a device, I can find it"
 (let [db (database)]
   (db:add sda-uevent)
   (let [[m & more] (db:find {:devname "sda"})]
     (expect= m.properties.devname "sda")
     (expect= m.properties.major "8")
     (expect= more []))))

(example
 "when I add a device, I cannot find it with wrong terms"
 (let [db (database)]
   (db:add sda-uevent)
   (expect= (db:find {:devname "sdb"}) [])))

(example
 "when I add a device, I can retrieve it by path"
 (let [db (database)]
   (db:add sda-uevent)
   (let [m (db:at-path "/devices/pci0000:00/0000:00:13.0/usb1/1-1/1-1:1.0/host0/target0:0:0/0:0:0:0/block/sda")]
     (expect= m.properties.devname "sda")
     (expect= m.properties.major "8"))))

(example
 "when I add and then remove a device, I cannot retrieve it by path"
 (let [db (database)]
   (db:add sdb1-insert)
   (db:add sdb1-remove)
   (expect= (db:at-path "/devices/pci0000:00/0000:00:14.0/usb1/1-3/1-3:1.0/host1/target1:0:0/1:0:0:0/block/sdb/sdb1") nil)))

(example
 "when I add and then remove a device, I cannot find it"
 (let [db (database)]
   (db:add sdb1-insert)
   (db:add sda-uevent)
   (db:add sdb1-remove)
   (expect= (db:find {:devname "/dev/sdb1"}) [])))

(example
 "when I search on multiple terms it uses all of them"
 (let [db (database)]
   (db:add sda-uevent)
   (expect= (# (db:find {:devname "sda" :devtype "disk"})) 1)
   (expect= (# (db:find {:devname "sda" :devtype "dosk"})) 0)))

(example
 "I can find a device with sysfs attributes"
 (let [db (database {:sys-path "./fixtures/sys"})
       path "/devices/pci0000:00/0000:00:14.0/usb1"
       e (.. "add@" path "\0ACTION=add\n"
             (with-open [f (io.open (.. "fixtures/sys" path "/uevent"))]
               (f:read "*a")))]
   (db:add e)
   (let [[m & more] (db:find {:devtype "usb_device" :attr {:idVendor "1d6b" }})]
     (expect= m.properties.driver "usb")
     (expect= m.properties.major "189")
     (expect= more []))
   (let [[m & more] (db:find {:devtype "usb_device" :attr {:idVendor "0000" }})]
     (expect (not m)))
   ))

(example
 "I can find a device matching ancestor sysfs attributes"
 (let [db (database {:sys-path "./fixtures/sys"})
       path "/devices/pci0000:00/0000:00:14.0/usb1/1-8/1-8:1.1"
       e (.. "add@" path "\0ACTION=add\n"
             (with-open [f (io.open (.. "fixtures/sys" path "/uevent"))]
               (f:read "*a")))]
   (db:add e)
   (let [[m & more] (db:find {:devtype "usb_interface"
                              :driver "uvcvideo"
                              :attrs {:idVendor "13d3"
                                      :manufacturer "Azurewave"
                                      }})]
     (expect= m.properties.driver "uvcvideo")
     (expect= m.properties.interface "14/2/0")
     (expect= more []))

   (let [[m & more] (db:find {:devtype "usb_interface"
                              :driver "uvcvideo"
                              :attrs {:idVendor "23d3"
                                      :manufacturer "Azurewave"
                                      }})]
     (expect (not m)))))

;;; tests for indices

(example "when I add a device with $attributes major minor foo bar baz,
 it is added to indices for foo bar baz but not major minor")

(example "a removed device can no longer be found by looking in any index")

(example "when I query with multiple attributes, the search is performed using the most specific attribute"
         ;; (= the attribute whose
         ;;   value at this key has fewest elements)
         )

;;; tests for subscriptions

(example
 "I can subscribe to some search terms and be notified of matching events"
 (var received [])
 (let [db (database)
       subscriber (fn [e] (table.insert received e))]
   (db:subscribe :me subscriber {:devname "/dev/sdb1"})
   (db:add sdb1-insert)
   (db:add sda-uevent)
   (db:add sdb1-remove)
   (expect= (# received) 2)))

(example
 "Subscribers get notifications of prior events for present devices"
 (var received [])
 (let [db (database)
       subscriber (fn [e] (table.insert received e))]
   (db:add sdb1-insert)
   (db:add sda-uevent)
   (db:subscribe :me subscriber {:devname "/dev/sdb1"})
   (expect= (# received) 1)))

(example
 "I can unsubscribe after subscribing"
 (var received [])
 (let [db (database)
       subscriber (fn [e] (table.insert received e))]
   (db:subscribe :me subscriber {:devname "/dev/sdb1"})
   (db:unsubscribe :me)
   (db:add sdb1-insert)
   (db:add sda-uevent)
   (db:add sdb1-remove)
   (expect= (# received) 0)))


;;; test for event loop

(example
 "I can register a fd with a callback"
 (let [loop (event-loop)
       cb #(print $1)]
   (loop:register 3 cb)
   (expect= (. (loop:_tbl) 3) cb)))

(example
 "when the fd is ready, my callback is called"
 (let [loop (event-loop)]
   (var ran? false)
   (loop:register 3 #(set ran? true))
   (loop:feed {3 1})
   (expect= ran? true)
   ))

(example
 "when the callback returns true it remains registered"
 (let [loop (event-loop)]
   (loop:register 3 #true)
   (loop:feed {3 1})
   (expect (. (loop:_tbl) 3))
   ))

(fn new-fd []
  (ll.open "/dev/zero" 0 0x1ff))

(example
 "when the callback returns false it is unregistered and the fd is closed"
 (let [loop (event-loop)
       fd (new-fd)]
   (expect (> fd 2))
   (loop:register 3 #false)
   (loop:feed {3 1})
   (expect (not (. (loop:_tbl) 3)))
   (assert (not (os.execute (string.format "test -e /dev/fd/%d" fd))))
   ))


(example
 "parse terms from string"
 (expect= (parse-terms "foo=bar baz=quuz")
          {:foo "bar" :baz "quuz" :attr {} :attrs {}})
 (expect= (parse-terms "foo=bar attr.womble=0x1234")
           {:foo "bar" :attr {:womble "0x1234"} :attrs {}}))

(if failed (os.exit 1) (print "OK"))
