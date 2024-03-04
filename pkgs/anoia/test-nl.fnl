(local nl (require :anoia.nl))
(local { : view } (require :fennel))

(let [events (nl.events {:link true})]
  (each [ev events]
    (print "got one ")
    (print (view ev))))
