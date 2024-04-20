(import-macros { : expect= } :anoia.assert)


(fn database []
  {
   :find (fn [terms] [])
   })


(macro example [description & body]
  `(do ,body))

(example
 "given an empty database, search for some criteria matches no entries"
 (let [db (database)]
   (expect= (db:find {:partname "boot"}) [])))



(print "OK")
