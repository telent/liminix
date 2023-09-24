(local subject (require :acquire-wan-address))
(local { : view } (require :fennel))
(local { : merge : dup } (require :anoia))


(local a1
       {
        "2001-ab-cd-ef_hjgKHGhKJH" {
                                    :address "2001:ab:cd:ef"
                                    :len "64"
                                    :preferred "200"
                                    :valid "200"
                                    }
        }
       )

(local a2
       {
        "2001-0-1-2-3_aNteBnb" {
                                :address "2001:0:1:2:3"
                                :len "64"
                                :preferred "200"
                                :valid "200"
                                }
        }
       )

(macro expect [assertion]
  (let [msg (.. "expectation failed: " (view assertion))]
    `(when (not ,assertion)
       (assert false ,msg))))

(fn first-address []
  (let [(add del)
        (subject.changes
         { }
         a1
         )]
    (expect (= (# del) 0))
    (expect (= (# add) 1))
    (let [[first] add]
      (expect (= first.address "2001:ab:cd:ef")))))

(fn second-address []
  (let [(add del)
        (subject.changes
         a1
         (merge (dup a1) a2)
         )]
    (expect (= (# del) 0))
    (expect (= (# add) 1))
    (let [[first] add] (expect (= first.address  "2001:0:1:2:3")))))

(fn less-address []1
  (let [(add del)
        (subject.changes
         (merge (dup a1) a2)
         a1
         )]
    (expect (= (# add) 0))
    (expect (= (# del) 1))

    (let [[first] del] (expect (= first.address  "2001:0:1:2:3")))))


(first-address)
(second-address)
(less-address)
