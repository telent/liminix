
(local state-directory (assert (os.getenv "SERVICE_STATE")))
(os.execute (.. "mkdir -p " state-directory))

(fn write-value [name value]
  (let [path (.. state-directory "/" name)]
    (with-open [fout (io.open path :w)]
      (when value (fout:write value)))))

(fn write-value-from-env [name]
  (write-value name (os.getenv (string.upper name))))

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
    (write-value-from-env n)))

(let [[ifname state] arg
      ready (match state
              "started" false
              "unbound" false
              "stopped" false
              _ true)]
  (write-value "last-update" (tostring (os.time)))
  (write-value "ifname" ifname)
  (write-value "state" state)
  (when ready
    (with-open [fd (io.open "/proc/self/fd/10" :w)] (fd:write "\n"))))
