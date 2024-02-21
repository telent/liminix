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

(fn system [s]
  (match (os.execute s)
    res (do (print (.. "Executed \"" s "\", exit code " (tostring res)))  res)
    (nil err) (error (.. "Error executing \"" s "\" (" err ")"))))

(fn hash [str]
  (accumulate [h 5381
               c (str:gmatch ".")]
    (+ (* h 33) (string.byte c))))


(local
 base64-indices
 (doto [
        "B" "C" "D" "E" "F" "G" "H" "I" "J" "K" "L" "M" "N" "O" "P"
        "Q" "R" "S" "T" "U" "V" "W" "X" "Y" "Z" "a" "b" "c" "d" "e" "f"
        "g" "h" "i" "j" "k" "l" "m" "n" "o" "p" "q" "r" "s" "t" "u" "v"
        "w" "x" "y" "z" "0" "1" "2" "3" "4" "5" "6" "7" "8" "9" "-" "_"
        ]
   (tset 0 "A")))

;; local function base64(s)
;;    local byte, rep = string.byte, string.rep
;;    local pad = 2 - ((#s-1) % 3)
;;    s = (s..rep('\0', pad)):gsub("...", function(cs)
;;       local a, b, c = byte(cs, 1, 3)
;;       return bs[a>>2] .. bs[(a&3)<<4|b>>4] .. bs[(b&15)<<2|c>>6] .. bs[c&63]
;;    end)
;;    return s:sub(1, #s-pad) .. rep('=', pad)
;; end

(fn base64url [s]
  "URL-safe Base64-encoded form of s (no trailing padding)"
  (let [pad (- 2 (% (- (# s) 1)  3))
        bs base64-indices
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


{ : merge : split : file-exists? : system : hash : base64url : dup }
