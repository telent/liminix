(local { : view } (require :fennel))
(local { : assoc : split } (require :anoia))

(local ctx (require :openssl.ssl.context))
(local csr (require :openssl.x509.csr))
(local pkey (require :openssl.pkey))
(local xn (require :openssl.x509.name))

(local http (require :fetch))

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
    (: :setVersion 3)
    (: :setSubject (x509-name options.subject))
    (: :setPublicKey pk)
    (: :addAttribute :challengePassword [options.secret])
    (: :sign pk)))


(fn http-post [url body]
  (match
      (http.request "POST" url
                    "" 0
                    "application/x-pem-file"
                    body)
    s s
    (nil code msg) (error (.. "Error " code " POST " url ": " msg))))


(fn run []
  (let [pk (private-key)
        csr (signing-request pk)
    ;; key-out (or options.key-out-handle io.stdout)
    ;; cert-out (or options.cert-out-handle io.stdout)
        cert (http-post options.server (csr:toPEM))]
    (with-open [f (ncall (io.open options.key-out :w))]
      (f:write (pk:toPEM :private)))
    (with-open [f (ncall (io.open options.certificate-out :w))]
      (f:write cert))
    (print "done")))


{ : run }
