(local svc (require :anoia.svc))
(local { : view } (require :fennel))

(local ex (svc.open "./example-output"))

(assert (= (ex:output "name") "eth1"))

(assert (=
         (table.concat (ex:output "colours"))
         (table.concat { :red "ff0000" :green "00ff00" :blu "0000ff" :black "000000" })))

(assert (=
         (table.concat (ex:output "addresses"))
         (table.concat {:1 {:attribute "a11"}
                        :3 {:attribute "a33"}
                        :5 {:attribute "a55"}
                        :6 {:attribute "a66"}})))
