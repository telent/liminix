(local yaml (require :lyaml))

;; (local { : view } (require :fennel))

(local outputs (collect [k v (ipairs arg)]
                 (values v true)))

(each [_ option (ipairs (yaml.load (io.read "*a")))]
  (when (. outputs option.name)
    (print (.. ".. _" option.name) "\n")
    (print option.description)))
