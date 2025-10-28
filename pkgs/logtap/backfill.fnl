(local { : file-exists? } (require :anoia))
(local tai64 (require :anoia.tai64))
(local { : write &as ll } (require :lualinux))

(local O_WRONLY 1)
(local O_RDWR 2)
(local O_CREAT 64)

(fn send-string [fd str]
  (case (write fd str)
    n (if (> (# str) n) (send-string (string.sub str n)) true)
    (nil code) nil))

(fn send-message [fd tai message]
  (let [ts (tai64.to-timestamp tai)]
    (send-string fd (.. ts  (string.sub message 26)))))

(fn parse-timestamp [message]
  (let [{ : s : n } (tai64.from-timestamp message)]
    (+ (* s 1000000000) n)))

(fn spit [filename body]
  (with-open [f (assert (io.open filename :w))]
    (f:write  body)))

(fn write-timestamp [file ts]
  (spit file (string.format "%d" ts))
  ts)

(fn slurp [filename]
  (with-open [f (assert (io.open filename :r))]
    (f:read "a")))

;; Any message which claims to have been generated before the
;; first public release of Linux is most likely instead generated
;; by a device that has no battery-backed clock and no
;; sync with NTP. Because the system clock starts at 1970-1-1
;; we treat this timestamp as an offset from the actual boot time

(local earliest-plausible-timestamp
       (tai64.from-unix (os.time {:year 1991 :month 9 :day 17})))

(fn read-boot-time []
  (let [uptime (with-open [f (io.open "/proc/uptime"  :r)] (f:read "n"))
        s (math.floor uptime)
        now (tai64.from-unix (os.time))]
    ;; we deduct an extra second to ensure there are no backfilled messages
    ;; sent with timestamps later than the earliest live message.
    {:s (- now.s s 1) :n 0 }))

(fn maybe-offset [timestamp boot-time]
  (if (< timestamp.s earliest-plausible-timestamp.s)
      {:s (+ timestamp.s boot-time.s) :n timestamp.n}
      timestamp))

(let [[fifo-name stampfile] arg
      boot-time (read-boot-time)
      fifo (ll.open fifo-name O_WRONLY 0)]
  (var backfill? true)
  (var next-ts
       (if (file-exists? stampfile)
           (tonumber (slurp stampfile))
           0))

  (each [l (: (io.input) :lines "L")]
    (case l
      "# LOG-SHIPPING-START\n"
      (set backfill? false)
      "# LOG-SHIPPING-STOP\n"
      (set backfill? true)
      message
      (let [tai  (tai64.from-timestamp message)
            message-ts (+ (* tai.s 1000000000) tai.n)]
        (when (> message-ts next-ts)
          (set next-ts (write-timestamp stampfile message-ts)))
        (when (>= message-ts next-ts)
          (if backfill?
              (let [actual-time (maybe-offset tai boot-time)]
                (when (not (send-message fifo actual-time message))
                  ;; If the fifo write fails, it could be a glitch or it
                  ;; could be some kind of wider outage.  Give up,
                  ;; and rely on the supervisor to restart us when
                  ;; conditions are again auspicious
                  (io.stderr:write "write failed\n")
                  (os.exit 1)))))))))
