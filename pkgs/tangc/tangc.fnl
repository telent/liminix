(local json (require :json))
(local http (require :fetch))
(local { : view : join } (require :fennel))
(local { : split : base64  : %%} (require :anoia))
(local { : popen2 } (require :anoia.fs))
(local ll (require :lualinux))



(local CLEVIS_DEFAULT_THP_LEN 43)        ;  Length of SHA-256 thumbprint.
(local thumbprint-algs ["S256" "S1"])

(fn exited [pid]
  (match (ll.waitpid pid)
    (0 status) false
    (pid status) (rshift (band status 0xff00) 8)
    (nil errno) (error (.. "waitpid: " errno))))

(fn min [a b] (if (< a b) a b))

(fn trace [s] (print :TRACE s) s)

(fn write-all [fd str]
  (let [written (ll.write fd str)]
    (if (< written (# str))
        (write-all fd (string.sub str (+ written 1) -1)))))


(fn jose [params inputstr]
  (let [env (ll.environ)
        (pid in out) (popen2 (os.getenv "JOSE_BIN") params env)]
    ;(print "exec " (os.getenv "JOSE_BIN") (view params))
    ;(print "writing")
    (when inputstr (write-all in inputstr))
    ;(print :written)
    (ll.close in)
    (let [output
          (accumulate [o ""
                       buf #(match (ll.read out) "" nil s s)]
            (.. o buf))]
      (values (exited pid) output))))

(fn has-key? [keys kid alg]
  (let [jkeys (json.encode keys)
        (exitcode srv) (jose
                        ["jose" "jwk" "thp" "-i-"
                         "-f" kid
                         "-a" alg]
                        jkeys)]
    (if (= exitcode 0)
        (json.decode srv)
        nil)))

(fn jwk-generate [crv]
  (let [(exitcode eph)
        (jose ["jose" "jwk" "gen"
               "-i" (%% "{\"alg\":\"ECMR\",\"crv\":%q}" crv)]
              "")]
    (if (= exitcode 0)
        (json.decode eph)
        (error (.. "Error generating ephemeral key: "  exitcode  "/"   eph) ))))

(fn jwk-pub [response]
  (let [(exitcode pub)
        (jose ["jose" "jwk" "pub" "-i-"]
               (json.encode response))]
    (if (= exitcode 0)
        (json.decode pub)
        (error (.. "Error pub "  exitcode  "/"   pub) ))))

(fn jwk-exc-noi [clt eph]
  (let [payload (.. (json.encode clt) " " (json.encode eph))
        (exitcode xfr)
        (jose ["jose" "jwk" "exc"
               "-l-" "-r-"]
              payload)]
    (if (= exitcode 0)
        (json.decode xfr)
        (error (.. "Error calling jwk exc: " exitcode " / " xfr  )))))

(fn jwk-exc [clt eph]
  (let [payload (.. (json.encode clt) " " (json.encode eph))
        (exitcode xfr)
        (jose ["jose" "jwk" "exc"
               "-i"   "{\"alg\":\"ECMR\"}"
               "-l-" "-r-"]
              payload)]
    (if (= exitcode 0)
        (json.decode xfr)
        (error (.. "Error calling jwk exc: " exitcode " / " xfr  )))))

(fn jwe-dec [jwk ph undigested]
  (let [payload (.. (json.encode jwk) ph undigested)
        ; _ (print :payload  payload)
        (exitcode plaintext)
        (jose ["jose" "jwe" "dec" "-k-" "-i-"]
              payload)]
    (if (= exitcode 0)
        plaintext
        (error (.. "Error calling jwe dec: " exitcode " / " plaintext )))))

(fn parse-jwe [jwe]
  (assert (= jwe.clevis.pin "tang") "invalid clevis.pin")
  (assert jwe.clevis.tang.adv "no advertised keys")
  (assert (>= (# jwe.kid) CLEVIS_DEFAULT_THP_LEN)
          "tang using a deprecated hash for the JWK thumbprints")
  (let [srv (accumulate [ret nil
                         _ alg (ipairs thumbprint-algs)
                         &until ret]
              (or ret (has-key? jwe.clevis.tang.adv jwe.kid alg)))]
    {
     :kid jwe.kid
     :clt (assert jwe.epk)
     :crv (assert jwe.epk.crv "Unable to determine EPK's curve!")
     :url (assert jwe.clevis.tang.url "no tang url")
     :srv (assert srv
                  "JWE header validation of 'clevis.tang.adv' failed: key thumbprint does not match")
   }))

(fn http-post [url body]
  (json.decode
   (http.request "POST" url
                 "" 0
                 "application/x-www-form-urlencoded"
                 body)))


(fn run []
  (let [b64 (base64 :url)
        raw (: (io.input) :read "*a")
        dot (string.find raw "." 1 true)
        ph (string.sub raw 1 dot)
        undigested (string.sub raw (+ 1 dot) -1)
        jwe (json.decode (b64:decode ph))
        { : srv : crv : clt : kid : url} (parse-jwe jwe)
        eph (jwk-generate crv)
        xfr (jwk-exc clt eph)
        response (http-post (.. url "/rec/" kid) (json.encode xfr))]

    (assert (and (= response.kty "EC") (= response.crv crv))
            "Received invalid server reply!")
    (let [tmp (jwk-exc eph srv)
          rep (jwk-pub response)
          jwk (jwk-exc-noi rep tmp)]
      (print (jwe-dec jwk ph undigested)))))

{ : run }
