(local json (require :json))
(local http (require :fetch))
(local { : base64  : %%} (require :anoia))
(local { : popen2 } (require :anoia.fs))
(local ll (require :lualinux))

(local CLEVIS_DEFAULT_THP_LEN 43)        ;  Length of SHA-256 thumbprint.
(local thumbprint-algs ["S256" "S1"])

(fn exited [pid]
  (match (ll.waitpid pid)
    (0 status) false
    (pid status) (rshift (band status 0xff00) 8)
    (nil errno) (error (.. "waitpid: " errno))))

(fn write-all [fd str]
  (let [written (ll.write fd str)]
    (if (< written (# str))
        (write-all fd (string.sub str (+ written 1) -1)))))

(fn jose [params inputstr]
  (let [env (ll.environ)
        argv (doto params (table.insert 1 "jose"))
        (pid in out) (popen2 (os.getenv "JOSE_BIN") argv env)]
    ;; be careful if using this code for commands othert than jose: it
    ;; may deadlock if we write more than 8k and the command doesn't
    ;; read it.
    (when inputstr (write-all in inputstr))
    (ll.close in)
    (let [output
          (accumulate [o ""
                       buf #(match (ll.read out) "" nil s s)]
            (.. o buf))]
      (values (exited pid) output))))

(fn jose! [params inputstr]
  (let [(exitcode out) (jose params inputstr)]
    (if (= exitcode 0)
        (json.decode out)
        (error (%% "jose %q failed (exit=%d): %q"
                   (table.concat params " ") exitcode out)))))

(fn josep! [params inputstr]
  (let [(exitcode out) (jose params inputstr)]
    (if (= exitcode 0)
        out
        (error (%% "jose %q failed (exit=%d): %q"
                   (table.concat params " ") exitcode out)))))

(fn has-key? [keys kid alg]
  (jose! ["jwk" "thp" "-i-" "-f" kid "-a" alg] (json.encode keys)))

(fn search-key [keys kid]
  (accumulate [ret nil
               _ alg (ipairs thumbprint-algs)
               &until ret]
    (or ret (has-key? keys kid alg))))

(fn jwk-generate [crv]
  (jose! ["jwk" "gen" "-i" (%% "{\"alg\":\"ECMR\",\"crv\":%q}" crv)] ""))

(fn jwk-pub [response]
  (jose! ["jwk" "pub" "-i-"] (json.encode response)))

(fn jwk-exc-noi [clt eph]
  (jose! ["jwk" "exc" "-l-" "-r-"]
         (.. (json.encode clt) " " (json.encode eph))))

(fn jwk-exc [clt eph]
  (jose! ["jwk" "exc" "-i"   "{\"alg\":\"ECMR\"}" "-l-" "-r-"]
         (.. (json.encode clt) " " (json.encode eph))))

(fn jwe-dec [jwk ph undigested]
  (josep! ["jwe" "dec" "-k-" "-i-"]
          (.. (json.encode jwk) ph "." undigested)))

(fn parse-jwe [jwe]
  (assert (= jwe.clevis.pin "tang") "invalid clevis.pin")
  (assert jwe.clevis.tang.adv "no advertised keys")
  (assert (>= (# jwe.kid) CLEVIS_DEFAULT_THP_LEN)
          "tang using a deprecated hash for the JWK thumbprints")
  (let [srv (search-key jwe.clevis.tang.adv jwe.kid)]
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
        (_ _ ph undigested) (string.find raw "(.-)%.(.+)")
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
