(local svc (require :svc))
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

(let [dir (. arg 1)
      ex2 (svc.open dir)]
  (ex2:output "fish" "food")
  (ex2:output "nested/path/name" "value")
  (ex2:output "nested/path/complex" {
                                     :attribute "val"
                                     :other "42"
                                     }))
