(fn hashes-from-file [name]
  (with-open [f (assert (io.open name :r) name)]
    (accumulate [h []
                 l #(f:read "*l")]
      (let [(name hash) (string.match l "([^%s]+) +([^%s]+)")]
        (if name
            (doto h (tset name hash))
            h)))))

(fn write-restarts [old new]
  (let [old-hashes (hashes-from-file old)
        new-hashes (hashes-from-file new)]
    (with-open [f (io.open "/tmp/restarts" :w)]
      (each [n h (pairs old-hashes)]
        (when (not (= h (. new-hashes n)))
          (f:write (.. n " restart\n")))))))

(fn exec [text command]
  (io.write (.. text ": "))
  (match (os.execute command)
    res (print "[OK]")
    (nil err) (error (.. "[FAILED " err "]"))))

(let [mypath (: (. arg 0) :match "(.*/)")
      activate (.. mypath "activate /")
      old-compiled "/run/s6-rc/compiled/"
      new-compiled "/etc/s6-rc/compiled/"]

  (exec "installing FHS files" activate)

  (write-restarts (.. old-compiled "hashes") (.. new-compiled "hashes"))

  (exec "updating service database"
        (.. "s6-rc-update -f /tmp/restarts " new-compiled))

  (exec "starting services" (.. "s6-rc -u -p change default"))
  )
