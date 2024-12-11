;; these are macros; this module should be imported
;; using import-macros

;; e.g. (import-macros { : expect= } :anoia.assert)

(fn expect [assertion]
  (let [msg (.. "expectation failed: " (view assertion))]
    `(when (not ,assertion)
       (assert false ,msg))))

(fn expect= [actual expected]
  `(let [view# (. (require :fennel) :view)
         ve# (view# ,expected)
         va# (view# ,actual)]
     (when (not (= ve# va#))
       (assert false
               (.. "\nexpected " ve# "\ngot " va#)
               ))))

(fn define-tests [& body]
  (when _G.RUNNING_TESTS
    `(do ,(unpack body))))

{ : define-tests : expect : expect=  }
