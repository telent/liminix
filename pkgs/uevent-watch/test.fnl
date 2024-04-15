(local { : view} (require :fennel))

(set _G.arg (doto [] (tset 0 "test")))
(local subject (require :watch))

(macro expect= [actual expected]
  `(let [ve# (view ,expected)
         va# (view ,actual)]
     (when (not (= ve# va#))
       (assert false
               (.. "\nexpected " ve# "\ngot " va#)
               ))))

(let [params
      {:matches {:devname "foo" :partname "my-usbstick"}}]
  (expect= (subject.event-matches? params {}) false)
  (expect= (subject.event-matches? params {:devname "bill"}) false)
  (expect= (subject.event-matches? params {:devname "foo" :partname "my-usbstick"}) true)
  (expect= (subject.event-matches? params {:devname "foo" :otherthing "bar" :partname "my-usbstick"}) true)
  )


;; Events come from the netlink socket as an initial summary line
;; followed by a NUL character followed by newline-separated key=value
;; pairs. For ease of editing we don't have NULs in events.txt,
;; so we need to massage it into shape here

(local events
       (with-open [f (io.open "./events.txt" :r)]
         (let [text (string.gsub (f:read "*a") "\n\n" "\0")  ]
           (icollect [n (string.gmatch text "([^\0]+)")]
             (string.gsub n "\n" "\0" 1)))))


(fn next-event []
  (var i 0)
  (fn []
    (let [i_ (+ 1 i)
          e (. events i_)]
      (set i i_)
      e)))

;; this tests event parsing but not whether anything
;; happens as a result of processing them
(subject.run
 ["-s" "foo" "-n" (os.getenv "TMPDIR") "partname=backup-disk" ]
 { :read (next-event) }
 )
