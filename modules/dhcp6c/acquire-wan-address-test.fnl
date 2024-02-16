(local subject (require :acquire-wan-address))
(local { : view } (require :fennel))
(local { : merge : dup } (require :anoia))


(local a1
       {
        "2001-ab-cd-ef" {
                      	 :address "2001:ab:cd:ef"
                         :len "64"
                         :preferred "3600"
                         :valid "7200"
                         }
        }
       )

(local a156
       {
        "2001-ab-cd-ef" {
                      	 :address "2001:ab:cd:ef"
                         :len "56"
                         :preferred "3600"
                         :valid "7200"
                         }
        }
       )

(local a2
       {
        "2001-0-1-2-3" {
                        :address "2001:0:1:2:3"
                        :len "64"
                        :preferred "3600"
                        :valid "7200"
                        }
        }
       )

(local a21
       {
        "2001-0-1-2-3" {
                        :address "2001:0:1:2:3"
                        :len "64"
                        :preferred "1800"
                        :valid "5400"
                        }
        }
       )

(macro expect [assertion]
  (let [msg (.. "expectation failed: " (view assertion))]
    `(when (not ,assertion)
       (assert false ,msg))))

(macro expect= [actual expected]
  `(let [ve# (view ,expected)
         va# (view ,actual)]
     (when (not (= ve# va#))
       (assert false
               (.. "\nexpected " ve# "\ngot " va#)
               ))))

(fn first-address []
  (let [deleted
        (subject.deletions
         { }
         a1
         )]
    (expect= deleted [])))

(fn second-address []
  (let [del
        (subject.deletions
         a1
         (merge (dup a1) a2)
         )]
    (expect= del [])))

(fn old-address-is-deleted []
  (let [del
        (subject.deletions
         (merge (dup a1) a2)
         a1
         )]
    (expect= (. del 1) (. a2 "2001-0-1-2-3"))
    ))

(fn changed-lifetime-not-deleted []
  (let [del
        (subject.deletions
         (merge (dup a1) a2)
         (merge (dup a1) a21)
         )]
    ;; when an address lifetime changes, "ip address change"
    ;; will update that so it need not (should not) be deleted
    (expect= del [])))

(fn changed-prefix-is-deleted []
  (let [del
        (subject.deletions a1 a156)]
    ;; when an address prefix changes, "ip address change"
    ;; ignores that cjhange, so we have to remove the
    ;; address before reinstating it
    (expect= del [(. a1 "2001-ab-cd-ef")])))

(first-address)
(second-address)
(old-address-is-deleted)
(changed-lifetime-not-deleted)
(changed-prefix-is-deleted)

(let [cmds []]
  (subject.update-addresses
   "ppp0" a1 (merge (dup a1) a2)
   (fn [a] (table.insert cmds a)))
  (expect=
   (doto cmds table.sort)
   [
    ;; order of changes is unimportant
    "ip address change 2001:0:1:2:3/64 dev ppp0 valid_lft 7200 preferred_lft 3600"
    "ip address change 2001:ab:cd:ef/64 dev ppp0 valid_lft 7200 preferred_lft 3600"
    ]))

(let [cmds []]
  (subject.update-addresses
   "ppp0" (merge (dup a1) a2) a1
   (fn [a] (table.insert cmds a)))
  (expect=
   cmds
   [
    ;; deletes are executed before changes
    "ip address del 2001:0:1:2:3/64 dev ppp0"
    "ip address change 2001:ab:cd:ef/64 dev ppp0 valid_lft 7200 preferred_lft 3600"
    ]))

(print "OK")
