(local { : hash : base64url } (require :anoia))
(import-macros { : expect= } :anoia.assert)

(expect= (hash "") 5381)

;; these examples from https://theartincode.stanis.me/008-djb2/
(expect= (hash "Hello") 210676686969)
(expect= (hash "Hello!") 6952330670010)

(expect= (base64url "hello world") "aGVsbG8gd29ybGQ")
