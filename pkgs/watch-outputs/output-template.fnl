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


(fn substitute [text opening closing]
  (let [delim (.. opening "(.-)" closing)
        myenv {
               : string
               :output
               (fn [service-path path]
                 (let [s (assert (svc.open (.. service-path "/.outputs")))]
                   (s:output path)))
               :lua_quote #(string.format "%q" %1)
               :json_quote (fn [x] (.. "\"" (json-escape x) "\""))
               }]
    (string.gsub text delim
                 (fn [x]
                   (assert ((load (.. "return " x) x :t myenv))
                           (string.format "missing value for %q" x))))))

(fn run []
  (let [[opening closing] arg
        out (substitute (: (io.input) :read "*a") opening closing)]
    (io.write out)))

{ : run }
