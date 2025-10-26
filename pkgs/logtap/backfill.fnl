(local { : file-exists? } (require :anoia))
(local tai64 (require :anoia.tai64))
(local { : write &as ll } (require :lualinux))

(local O_WRONLY 1)
(local O_RDWR 2)
(local O_CREAT 64)

(fn send-message [fd message]
  (case (write fd message)
    n (if (> (# message) n) (send-message (string.sub message n)) true)
    (nil code) nil))

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

(let [[fifo-name stampfile] arg
      fifo (ll.open fifo-name O_WRONLY)]
  (var backfill? true)
  (var next-ts
       (if (file-exists? stampfile)
           (tonumber (slurp stampfile))
           0))

  (each [l (: (io.input) :lines  "L")]
    (case l
      "START SHIPPING"
      (set backfill? false)
      "STOP SHIPPING"
      (set backfill? true)
      message
      (let [message-ts (parse-timestamp message)]
        (when (> message-ts next-ts)
          (set next-ts (write-timestamp stampfile message-ts)))
        (when (>= message-ts next-ts)
          (io.stderr:write (.. "writing " message backfill?))
          (if backfill?
              (when (not (send-message fifo message))
                ;; If the fifo write fails, it could be a glitch or it
                ;; could be some kind of wider outage.  Give up,
                ;; and rely on the supervisor to restart us when
                ;; conditions are again auspicious
                (io.stderr:write "write failed\n")
                (os.exit 1))))))))
