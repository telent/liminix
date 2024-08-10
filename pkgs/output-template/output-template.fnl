(local svc (require :anoia.svc))

(fn substitute [text service opening closing]
  (let [delim (.. opening "(.-)" closing)
        myenv {
               : string
               :secret (fn [x] (service:output x))
               :lua_quote #(string.format "%q" %1)
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
