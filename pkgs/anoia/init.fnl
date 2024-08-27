;; importing assert.fnl macros here would be circular, so we can't use
;; the full test functionality
(macro define-tests [& body]
  (when _G.RUNNING_TESTS
    `(do ,(unpack body))))

(fn assoc [tbl k v & more]
  (tset tbl k v)
  (case more
    [k v] (assoc tbl k v)
    _ tbl))

(fn merge [table1 table2]
  (collect [k v (pairs table2) &into table1]
    k v))

(fn dup [table]
  (collect [k v (pairs table)] k v))

(fn split [sep string]
  (icollect [v (string.gmatch string (.. "([^" sep "]+)"))]
    v))

(fn file-exists? [name]
  (match (io.open name :r)
    f (do (f:close) true)
    _ false))

(fn basename [path]
  (string.match path ".*/([^/]-)$"))

(fn dirname [path]
  (string.match path "(.*)/[^/]-$"))

(fn system [s]
  (match (os.execute s)
    res (do (print (.. "Executed \"" s "\", exit code " (tostring res)))  res)
    (nil err) (error (.. "Error executing \"" s "\" (" err ")"))))

(fn hash [str]
  (accumulate [h 5381
               c (str:gmatch ".")]
    (+ (* h 33) (string.byte c))))

(fn table= [a b]
  (if (= a b)
      true
      (and (= (type a) :table) (= (type b) :table)
           (accumulate [equal true
                        k v1 (pairs a)
                        &until (not equal)]
             ;; all keys in a have the same value in a and b
             (and equal
                  (let [v2 (. b k)] (and v2 (table= v1 v2)))))
           (accumulate [present true
                        k _ (pairs b)
                        &until (not present)]
             ;; there are no keys in b which are not also in a
             (and present (. a k))))))

(define-tests
 (assert (table= {:a 1 :b 2} {:b 2 :a 1}))
 (assert (not (table= {:a 1 :b 2 :k :l}  {:b 2 :a 1})))
 (assert (not (table= {:a 1 :b 2}  {:b 2 :a 1 :k :l})))

 (assert (table= {:a 1 :b {:l 17}} {:b {:l 17} :a 1}))
 (assert (table= {:a [4 5 6 7] } {:a [4 5 6 7]}))
 (assert (not (table= {:a [4 5 6 7] } {:a [4 5 6 7 8]})))
 (assert (not (table= {:a [4 5 7 6] } {:a [4 5 6 7 ]}))))

(fn dig [tree path]
  (match path
    [el & more] (dig (. tree el) more)
    [el] (. tree el)
    [] tree))

(fn %% [fmt ...] (string.format fmt ...))

(local
 base64-indices
 (let [base [
         "B" "C" "D" "E" "F" "G" "H" "I" "J" "K" "L" "M" "N" "O" "P"
         "Q" "R" "S" "T" "U" "V" "W" "X" "Y" "Z" "a" "b" "c" "d" "e" "f"
         "g" "h" "i" "j" "k" "l" "m" "n" "o" "p" "q" "r" "s" "t" "u" "v"
         "w" "x" "y" "z" "0" "1" "2" "3" "4" "5" "6" "7" "8" "9"
         ]]
   {
    :url
    (merge (dup base)
           { 0 "A"
             62 "-"
             63 "_" })
    :standard
    (merge (dup base)
           { 0 "A"
             62 "+"
             63 "/" })
    }))


(fn base64-encode [s bs]
  (let [pad (- 2 (% (- (# s) 1)  3))
        blank (string.rep "\0" pad)
        s (-> (.. s blank)
              (: :gsub
                 "..."
                 (fn [cs]
                   (let [(a b c) (string.byte cs  1 3)]
                     (.. (. bs (rshift a 2))
                         (. bs (bor (lshift (band a 3) 4)  (rshift b 4)))
                         (. bs (bor (lshift (band b 15) 2) (rshift c 6)))
                         (. bs (band c 63)))))))]
    (s:sub 1 (- (# s) pad))))

(fn base64-decode [input rindices]
  ;; take groups of 4 characters, reverse-look them up in base64-indices,
  ;; convert to 24 bit number,
  ;; convert to three characters
  (let [padding (if (= (string.sub input -2 -1) "==") -3
                    (= (string.sub input -1 -1) "=") -2
                    -1)
        input (string.sub (.. input "===") 1 (* (/ (# input) 4) 4))]
    (->
     (icollect [s (string.gmatch input "(....)")]
       (let [(a b c d) (string.byte s 1 4)
             ri (fn [x] (assert (. rindices x) (.. "invalid " x)))
             n (bor (ri d)
                    (lshift (ri c) 6)
                    (lshift (ri b) 12)
                    (lshift (ri a) 18))]


         (string.pack "bbb"
                      (rshift (band 0xff0000 n) 16)
                      (rshift (band 0x00ff00 n) 8)
                      (band 0x0000ff n))))
     (table.concat "")
     (string.sub 1 padding)
     )))

(fn base64 [alphabet-des]
  (let [alphabet (or (. base64-indices alphabet-des) alphabet-des (. base64-indices :standard) )
        ralphabet (doto
                      (collect [k v (pairs alphabet)]
                        (values (string.byte v) k))
                    (tset (string.byte "=") 0))]
    {
     :encode (fn [_ str] (base64-encode str alphabet))
     :decode (fn [_ str] (base64-decode str ralphabet))
     }))

(fn base64url [str] (: (base64 :url) :encode str))



(define-tests
  (let [{: view} (require :fennel)
        b64 (base64 :url)]

    (let [a (b64:decode "YWxsIHlvdXIgYmFzZQ==")]
      (assert (= a "all your base") (view a)))
    (let [a (b64:decode "ZmVubmVsIHRoaW5n")]
      (assert (= a "fennel thing")  a))
    (let [a (b64:decode "TWFueSBoYW5kcyBtYWtlIGxpZ2h0IHdvcms=")]
      (assert (= a "Many hands make light work") (view  a)))
    (let [a (b64:encode "hello world")]
      (assert (= a "aGVsbG8gd29ybGQ") a))))


    ;; doesn't work if the padding is missing
    ;; (let [a (from-base64 "TWFueSBoYW5kcyBtYWtlIGxpZ2h0IHdvcms")]
    ;;   (assert (= a "Many hands make light work") (view  a)))
;    ))



{
 : assoc
 : base64
 : base64url
 : basename
 : dig
 : dirname
 : dup
 : file-exists?
 : hash
 : merge
 : split
 : system
 : table=
 : %%
 }
