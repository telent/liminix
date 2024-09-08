(local { : base64 } (require :anoia))
(local ll (require :lualinux))

(fn index [str indexname]
  (string.format "{\"index\":{\"_index\":%q}}\n%s" indexname str))

(local crlf "\r\n")

(fn chunk [str]
  (let [len (# str)]
    (string.format "%x%s%s%s" len crlf str crlf)))

(fn http-header [host path auth]
  (string.format
   "POST %s HTTP/1.1\r
Host: %s\
Authorization: basic %s
Transfer-Encoding: chunked\r
\r
"
   path host
   (let [b64 (base64 :url)] (b64:encode auth))))

(fn format-timestamp [timestamp]
  ;; I can't make zincsearch understand any epoch-based timestamp
  ;; formats, so we are formatting dates as iso-8601 and damn the leap
  ;; seconds :-(
  (let [secs (- (tonumber (string.sub timestamp 1 16) 16)
                (lshift 1 62))
        nano (tonumber (string.sub timestamp 16 24) 16)
        ts (+ (* secs 1000) (math.floor (/ nano 1000000)))]
    (.. (os.date "!%FT%T" secs) "." nano "Z")))

(fn process-line [indexname hostname line]
  (let [(timestamp service msg) (string.match line "@(%x+) (%g+) (.+)$")]
    (->
     (string.format
      "{%q:%q,%q:%q,%q:%q,%q:%q}\n"
      "@timestamp" (format-timestamp timestamp)
      :service service
      :message msg
      :host hostname)
     (index indexname)
     chunk)))

(fn run []
  (let [myhostname (with-open [h (io.popen "hostname" :r)] (h:read "l"))
        (filename loghost credentials indexname) (table.unpack arg)]

    (with-open [infile (assert (io.open filename :r))]
      (ll.write 1 (http-header loghost "/api/_bulk" credentials))
      (while (case (infile:read "l")
               line (ll.write 1 (process-line indexname myhostname line))))
      (ll.write 1 (chunk "")))
    (io.stderr:write (ll.read 0))))


{ : run }
