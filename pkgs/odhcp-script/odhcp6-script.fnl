(local { : split : merge : mkdir } (require :anoia))
(local { : view } (require :fennel))

(local state-directory (assert (os.getenv "SERVICE_STATE")))

(mkdir state-directory)

(fn write-value [name value]
  (let [path (.. state-directory "/" name)]
    (with-open [fout (io.open path :w)]
      (when value (fout:write value)))))

(fn write-value-from-env [name]
  (write-value name (os.getenv (string.upper name))))

;; Format: <prefix>/<length>,preferred,valid[,excluded=<excluded-prefix>/<length>][,class=<prefix class #>]

;;(parse-prefix "2001:8b0:de3a:40dc::/64,7198,7198")
;;(parse-prefix "2001:8b0:de3a:1001::/64,7198,7188,excluded=1/2,thi=10")

(fn parse-prefix [str]
  (fn parse-extra [s]
    (let [out {}]
      (each [name val (string.gmatch s ",(.-)=([^,]+)")]
        (tset out name val))
      out))
  (let [(prefix len preferred valid extra)
        (string.match str "(.-)::/(%d+),(%d+),(%d+)(.*)$")]
    (merge {: prefix : len : preferred : valid} (parse-extra extra))))


(fn parse-address [str]
  (fn parse-extra [s]
    (let [out {}]
      (each [name val (string.gmatch s ",(.-)=([^,]+)")]
        (tset out name val))
      out))
  (let [(address len preferred valid extra)
        (string.match str "(.-)/(%d+),(%d+),(%d+)(.*)$")]
    (merge {: address : len : preferred : valid} (parse-extra extra))))


(fn write-addresses [addresses]
  (each [_ a (ipairs (split " " addresses))]
    (let [address (parse-address a)
          keydir (.. "address/" (address.address:gsub ":" "-"))]
      (mkdir (.. state-directory "/" keydir))
      (each [k v (pairs address)]
        (write-value (.. keydir "/" k) v)))))

(fn write-prefixes [prefixes]
  (each [_ a (ipairs (split " " prefixes))]
    (let [prefix (parse-prefix a)
          keydir (.. "prefix/" (prefix.prefix:gsub ":" "-"))]
      (mkdir (.. state-directory "/" keydir))
      (each [k v (pairs prefix)]
        (write-value (.. keydir "/" k) v)))))

;; we remove state before updating to ensure that consumers don't get
;; a half-updated snapshot
(os.remove (.. state-directory "/state"))

(let [wanted
      [
       :addresses
       :aftr
       :cer
       :domains
       :lw406
       :mape
       :mapt
       :ntp_fqdn
       :ntp_ip
       :option_1
       :option_2
       :option_3
       :option_4
       :option_5
       :passthru
       :prefixes
       :ra_addresses
       :ra_dns
       :ra_domains
       :ra_hoplimit
       :ra_mtu
       :ra_reachable
       :ra_retransmit
       :ra_routes
       :rdnss
       :server
       :sip_domain
       :sip_ip
       :sntp_ip
       :sntp_fqdn
       ]]
  (each [_ n (ipairs wanted)]
    (write-value-from-env n))
  (write-addresses (os.getenv :ADDRESSES))
  (write-prefixes (os.getenv :PREFIXES)))

(let [[ifname state] arg
      ready (match state
              "started" false
              "unbound" false
              "stopped" false
              _ true)]
  (write-value ".lock" (tostring (os.time)))
  (write-value "ifname" ifname)
  (write-value "state" state)
  (os.remove (.. state-directory "/.lock"))
  (when ready
    (with-open [fd (io.open "/proc/self/fd/10" :w)] (fd:write "\n"))))
