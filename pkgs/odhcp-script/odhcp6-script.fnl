(local { : split : merge : hash : base64url } (require :anoia))
(local { : mktree : rmtree } (require :anoia.fs))

(local state-directory (assert (os.getenv "SERVICE_STATE")))
(mktree state-directory)

(fn write-value [name value]
  (let [path (.. state-directory "/" name)]
    (with-open [fout (io.open path :w)]
      (when value (fout:write value)))))

(fn write-value-from-env [name]
  (write-value name (os.getenv (string.upper name))))

(fn parse-address [str]
  (fn parse-extra [s]
    (let [out {}]
      (each [name val (string.gmatch s ",(.-)=([^,]+)")]
        (tset out name val))
      out))
  (let [(address len preferred valid extra)
        (string.match str "(.-)/(%d+),(%d+),(%d+)(.*)$")]
    (merge {: address : len : preferred : valid} (parse-extra extra))))

(fn write-addresses [prefix addresses]
  (each [_ a (ipairs (split " " addresses))]
    (let [address (parse-address a)
          suffix (base64url (string.pack "n" (hash a)))
          ;; keydir should be a function of all the address
          ;; attributes: we want it to change whenever anything changes
          ;; so that clients can see which addresses are new without
          ;; deep table comparisons
          keydir (..
                  prefix
                  (-> address.address
                      (: :gsub "::$" "")
                      (: :gsub ":" "-"))
                  "_"
                  suffix)]
      (mktree (.. state-directory "/" keydir))
      (each [k v (pairs address)]
        (write-value (.. keydir "/" k) v)))))

;; we remove state before updating to ensure that consumers don't get
;; a half-updated snapshot
(os.remove (.. state-directory "/state"))

;; remove parsed addresses/prefixes from any previous run
(rmtree (.. state-directory "/prefix"))
(rmtree (.. state-directory "/address"))

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

  (write-addresses "address/" (os.getenv :ADDRESSES))
  (write-addresses "prefix/" (os.getenv :PREFIXES)))

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
