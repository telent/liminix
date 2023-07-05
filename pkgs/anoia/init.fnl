(fn merge [table1 table2]
  (collect [k v (pairs table2) &into table1]
    k v))

(fn split [sep string]
  (icollect [v (string.gmatch string (.. "([^" sep "]+)"))]
    v))

(fn file-exists? [name]
  (match (io.open name :r)
    f (do (f:close) true)
    _ false))

(fn system [s] (assert (os.execute s)))

{ : merge : split : file-exists? : system }
