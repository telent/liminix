(local fennel (require :fennel))
(local specials (require :fennel.specials))

(local compiler-env
       (doto (. (specials.make-compiler-env) :_G)
         (tset "RUNNING_TESTS" true)))

(each [_ f (ipairs arg)]
  (print :testing f)
  (fennel.dofile f { :correlate true :compilerEnv compiler-env }))
