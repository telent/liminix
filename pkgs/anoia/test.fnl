(local { : hash : base64url } (require :anoia))

(assert (= (hash "") 5381))

;; these examples from https://theartincode.stanis.me/008-djb2/
(assert (= (hash "Hello") 210676686969))
(assert (= (hash "Hello!") 6952330670010))

(assert (= (base64url "hello world") "aGVsbG8gd29ybGQ"))
