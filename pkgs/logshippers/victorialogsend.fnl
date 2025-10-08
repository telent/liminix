(local { : base64 : assoc } (require :anoia))
(local tai64 (require :anoia.tai64))
(local ll (require :lualinux))
(import-macros { : expect= : define-tests } :anoia.assert)

(local crlf "\r\n")

(fn chunk [str]
  (let [len (# str)]
    (string.format "%x%s%s%s" len crlf str crlf)))

(fn parse-url [str]
  ;; this is a very poor parser as it won't recognise
  ;; credentials in the authority and it lumps query-string/fragment
  ;; into the path
  (let [(scheme host path)
        (string.match str "(.-)://(.-)(/.+)")]
    { : scheme : host : path }))

(define-tests
  (expect= (parse-url "https://www.example.com/stairway/to/heaven")
           { :scheme "https"
             :host "www.example.com"
             :path "/stairway/to/heaven"
             }))

(fn parse-args [args]
  (case args
    ["--basic-auth" auth & rest]
    (assoc (parse-args rest) :auth auth)

    [url] { :url (parse-url url) }
    _ (error "invalid args")))


(fn http-header [host path auth]
  (let [b64 (base64 :url)
        authstr
        (if auth
            (string.format "Authorization: basic %s\n" (b64:encode auth))
            "")]
    (string.format
   "POST %s HTTP/1.1\r
Host: %s\
%sTransfer-Encoding: chunked\r
\r
"
   path host authstr)))

(fn format-timestamp-rfc3339 [timestamp prec]
  (let [(sec nano) (-> timestamp tai64.from-timestamp tai64.to-utc)
        subsec (string.sub (string.format "%09d" nano) 1 prec)]
    (.. (os.date "!%FT%T" sec)
        "." subsec
        "Z")))

(define-tests
  (expect=  (format-timestamp-rfc3339 "@4000000068e2f0d3257dc09b"  9)
            "2025-10-05T22:26:54.628998299Z")
  (expect=  (format-timestamp-rfc3339 "@4000000068e2f0d3257dc09b"  3)
            "2025-10-05T22:26:54.628Z"))

(fn process-line [line]
  (let [(timestamp hostname service msg) (string.match line "(@%x+) (%g+) (%g+) (.+)$")]
    (->
     (if timestamp
         (string.format
          "{%q:%q,%q:%q,%q:%q,%q:%q}\n"
          :_time (format-timestamp-rfc3339 timestamp 3)
          :service service
          :_msg msg
          :host hostname)
         (string.format
          "{%q:%q,%q:%q,%q:%q,%q:%q}\n"
          :_time (os.date "!%FT%TZ")
          :service "ERROR"
          :_msg (string.format "can't parse log %q" msg)
          :host hostname))
     chunk)
    ))

(fn writefd [fd body]
  (case (ll.write fd body)
    (bytes) (when (< bytes (# body)) (writefd fd (string.sub body bytes)))
    (nil errno)
    (error (string.format "write to fd %d failed: %s" fd (ll.strerror errno))))
  true)

(fn run []
  (let [{ : auth : url } (parse-args arg)
        in-fd 6
        out-fd 7]
    (writefd out-fd (http-header url.host url.path auth))
    (while (case (io.stdin:read "l")
             line (writefd out-fd (process-line line))))
    (writefd out-fd (chunk ""))
    (io.stderr:write (ll.read in-fd))))


{ : run }
