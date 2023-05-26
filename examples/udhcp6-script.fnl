

(fn write-value [name value]
  (with-open [fout (io.open name :w)]
    (when value (fout:write value))))

(write-value "state" (. arg 2))
(write-value "ifname" (. arg 1))

(fn write-value-from-env [name]
  (write-value name (os.getenv (string.upper name))))

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

(let [ready (match state
              "started" false
              "unbound" false
              "stopped" false
              _ true)]
  (and ready
       (with-open [fd (io.open "/proc/self/fd/10" :w)] (fd:write "\n"))))
