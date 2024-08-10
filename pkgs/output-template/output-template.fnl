(local svc (require :anoia.svc))

(fn json-escape [s]
  ;; All Unicode characters may be placed within the quotation marks,
  ;; except for the characters that MUST be escaped:
  ;; quotation mark, reverse solidus, and the control characters (U+0000
  ;; through U+001F). (RFC 8259)
  (-> s
      (string.gsub
       "[\"\b\f\n\r\t]" {
                         "\b" "\\b"
                         "\"" "\\\""
                         "\f" "\\f"
                         "\n" "\\n"
                         "\r" "\\r"
                         "\t" "\\t"
                         })
      (string.gsub
       "([\x00-\x1b])"
       (fn [x] (string.format "\\u%04X" (string.byte x))))))


(fn substitute [text service opening closing]
  (let [delim (.. opening "(.-)" closing)
        myenv {
               : string
               :secret (fn [x] (service:output x))
               :lua_quote #(string.format "%q" %1)
               :json_quote (fn [x] (.. "\"" (json-escape x) "\""))
               }]
    (string.gsub text delim
                 (fn [x]
                   (assert ((load (.. "return " x) x :t myenv))
                           (string.format "missing value for %q" x))))))

(fn run []
  (let [[service-dir opening closing] arg
        service (assert (svc.open service-dir))
        out  (substitute (: (io.input) :read "*a") service opening closing)]
    (io.write out)))


{ : run }
