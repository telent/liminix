(local { : database } (require :devout))
(local { : view } (require :fennel))
(import-macros { : expect= } :anoia.assert)

(var failed false)
(fn fail [d msg] (set failed true) (print :FAIL d (.. "\n" msg)))

(macro example [description & body]
  `(let [(ok?# err#) (xpcall (fn [] ,body) debug.traceback)]
     (if ok?#
         (print :PASS ,description)
         (fail ,description err#))))

(example
 "given an empty database, searching it finds no entries"
 (let [db (database)]
   (expect= (db:find {:partname "boot"}) [])))

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

(example
 "when I add a device, I can find it"
 (let [db (database)]
   (db:add sda-uevent)
   (let [[m & more] (db:find {:devname "sda"})]
     (expect= m.devname "sda")
     (expect= m.major "8")
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
     (expect= m.devname "sda")
     (expect= m.major "8"))))

(example
 "when I search on multiple terms it uses all of them"
 (let [db (database)]
   (db:add sda-uevent)
   (expect= (# (db:find {:devname "sda" :devtype "disk"})) 1)
   (expect= (# (db:find {:devname "sda" :devtype "dosk"})) 0)))



(if failed (os.exit 1) (print "OK"))
