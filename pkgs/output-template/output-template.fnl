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
               : table
               : ipairs
               :output
               (fn [service-path path default]
                 (let [s (assert (svc.open (.. service-path "/.outputs")))]
                   (or (s:output path) default)))
               :lua_quote #(string.format "%q" $1)
               :json_quote (fn [x] (.. "\"" (json-escape x) "\""))
               }]
    (string.gsub text delim
                 (fn [x]
                   (let [chunk (if (= (x:sub 1 1) ";")
                                   (x:sub 2)
                                   (.. "return " x))]
                     (assert ((load chunk x :t myenv))
                             (string.format "missing value for %q" x)))))))

(fn run []
  (let [[opening closing] arg
        out (substitute (: (io.input) :read "*a") opening closing)]
    (io.write out)))

(import-macros { : define-tests : expect : expect= } :anoia.assert)
(define-tests
  (expect= (pick-values 1 (substitute "var={{ 2 + 3 }}" "{{" "}}")) "var=5")
  (expect= (pick-values 1 (substitute "{{ json_quote(\"o'reilly\") }}" "{{" "}}"))
           "\"o'reilly\"")

  (expect= (pick-values 1 (substitute "{{; local a=9; return a }}" "{{" "}}")) "9")

  ;; "globals" set in one interpolation are available in subsequent ones
  (expect= (pick-values 1 (substitute "{{; a=42; return a }} {{ a and 999 or 0 }}" "{{" "}}")) "42 999")

  (fn slurp [name]
    (with-open [f (assert (io.open name))] (f:read "*a")))
  (expect=
   (pick-values 1 (substitute (slurp "example.ini")  "{{" "}}"))
   (slurp "example.ini.expected")))

{ : run }
