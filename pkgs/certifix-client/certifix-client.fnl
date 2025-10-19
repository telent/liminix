(local { : view } (require :fennel))
(local { : assoc : split } (require :anoia))

(local ctx (require :openssl.ssl.context))
(local csr (require :openssl.x509.csr))
(local altname (require :openssl.x509.altname))
(local pkey (require :openssl.pkey))
(local xn (require :openssl.x509.name))

(local request (require :http.request))
(local http_tls (require :http.tls))
(local x509 (require :openssl.x509))

(macro ncall [f]
  `(case ,f
     ok# ok#
     (nil err#) (error err#)))


(fn x509-name [subj]
  (let [n (xn.new)]
    (each [_ c (ipairs (split "," subj))]
      (let [(k v) (string.match c "(.-)=(.+)")]
        (n:add k v)))
    n))

(fn x509-altname [subj]
  (let [an (altname.new)]
    (each [_ c (ipairs (split "," subj))]
      (let [(k v) (string.match c "(.-)=(.+)")]
        (if (= k "CN") (an:add "DNS" v))))
    an))

(fn parse-args [args]
  (case args
    ["--secret" secret & rest]
    (assoc (parse-args rest)
           :secret (with-open [f (ncall (io.open secret :r))] (f:read "l")))

    ["--subject" subject & rest]
    (assoc (parse-args rest) :subject subject)

    ["--key-out" pathname & rest]
    (assoc (parse-args rest) :key-out pathname)

    ["--certificate-out" pathname & rest]
    (assoc (parse-args rest) :certificate-out pathname)

    [server] { : server }
    _ {}))


(local options (parse-args arg))

(fn private-key []
  (pkey.new { :type :rsa :bits 1024 }))

(fn signing-request [pk]
  (doto (csr.new)
    (: :setVersion 1)
    (: :setSubject (x509-name options.subject))
    (: :setSubjectAlt (x509-altname options.subject))
    (: :setPublicKey pk)
    (: :addAttribute :challengePassword [options.secret])
    (: :sign pk)))

(fn http-post [url  body]
  (let [r (request.new_from_uri url)
        h r.headers]
    (h:upsert ":method" :POST)
    (h:upsert "content-type" "application/x-pem-file")
    (when body
      (r:set_body body))
    (or
     (case (r:go)
       (headers stream)
       (if (= (headers:get ":status") "200")
           (stream:get_body_as_string)
           (error (.. "error response from server: "
                      (headers:get ":status"))))

       (nil failure)
       (error (.. "error: " failure))))))

(fn run []
  (let [pk (private-key)
        csr (signing-request pk)
        cert (http-post options.server (csr:toPEM))]
    (with-open [f (ncall (io.open options.key-out :w))]
      (f:write (pk:toPEM :private)))
    (with-open [f (ncall (io.open options.certificate-out :w))]
      (f:write cert))
    (print "done")))


{ : run }
