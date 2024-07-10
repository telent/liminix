(local yaml (require :lyaml))

;; (local { : view } (require :fennel))

(fn output? [option]
  (match option.loc
    ["system" "outputs" & _] true
    _ false))

(fn sorted-options [options]
  (table.sort
   options
   (fn [a b] (< a.name b.name)))
  options)

(each [_ option (ipairs (sorted-options (yaml.load (io.read "*a"))))]
  (when (and (output? option) (not option.internal))
    (print (.. ".. _" (string.gsub option.name "%." "-") ":") "\n")
    (print option.description "\n")))
