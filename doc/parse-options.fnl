(local yaml (require :lyaml))

(local { : view } (require :fennel))

(fn headline [name]
  (let [(_ _ basename) (string.find name ".*/([^/].*)")
        len (basename:len)]
    (print basename)
    (print (string.rep "=" len))))

(fn read-preamble [pathname]
  (if (= (pathname:sub 1 1) "/")
      (let [pathname (if (string.match pathname ".nix$")
                         pathname
                         (.. pathname "/default.nix"))]
        (with-open [f (assert (io.open pathname :r))]
          (accumulate [lines ""
                       l (f:lines)
                       :until (not (= (string.sub l 1 2) "##"))]
            (.. lines (string.gsub l "^## *" "") "\n"))))))

(fn strip-newlines [text]
  (-> text
      (string.gsub "\n([^\n])" " %1")
      (string.gsub "\n\n+" "\n")))

(fn indent [n text]
  (let [margin (string.rep " " n)]
    (.. margin (string.gsub (or text "") "\n +" (.. "\n" margin )))))

(fn indent-literal [n text]
  (let [margin (string.rep " " n)]
    (.. margin (string.gsub (or text "") "\n" (.. "\n" margin )))))

(fn extract-text [description]
  (match description
    { :_type "literalExpression" : text } text
    (where s (= (type s) "string")) description
    _ nil))

(fn print-option [o offset]
  (let [i (or offset 0)]
    (print (indent i (.. " * option ``" o.name "``")))
    (case (-?> o.description extract-text strip-newlines)
          descr (print (indent (+ 4 i) descr)))
    (print)
    (print (indent (+ 4 i) (.. "**type** " o.type "\n")))
    (when o.example
      (print (indent (+ 4 i) "**example**")) (print)
      (print (indent (+ 4 i) ".. code-block:: nix"))
      (print)
      (print (indent-literal (+ 8 i) (extract-text o.example)) "\n")
      (print))

    (when (extract-text o.default)
      (print (indent (+ 4 i) "**default**")) (print)
      (print (indent (+ 4 i) ".. code-block:: nix"))
      (print)
      (print (indent-literal (+ 8 i) (extract-text o.default)) "\n")
      (print))))

(fn print-service [o]
  (print (.. " * service ``" o.name "``"))
  (match (extract-text o.description)
    descr (print (indent 4 descr)))
  (print)
  (print (indent 4 "**Service parameters**\n"))
  (each [_ param (ipairs o.parameters)]
    (print-option param 4)))

(fn output? [option]
  (match option.loc
    ["system" "outputs" & _] true
    _ false))

(fn sort-options [module]
  (let [options (icollect [_ o (ipairs module)]
                  (if (not (output? o))
                      o))]
    (doto options (table.sort  (fn [a b] (< a.name b.name))))))

(let [raw (yaml.load (io.read "*a"))
      modules {}]
  (each [_ option (ipairs raw)]
    (each [_ path (ipairs option.declarations)]
      (let [e (or (. modules path) [])]
        (table.insert e option)
        (tset modules path e))))
  (tset modules "lib/modules.nix" nil)
  (let [module-names (doto (icollect [n _ (pairs modules)] n) table.sort)]
    (io.stderr:write (view module-names))
    (each [_ name (ipairs module-names)]
      (let [module (. modules name)
            options (sort-options module)]
        (print (or (read-preamble name) (headline name)))
        (each [_ o (ipairs options)]
          (if (= o.type "parametrisable s6-rc service definition")
              (print-service o)
              (print-option o)))))))
