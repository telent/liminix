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
  (and text
       (-> text
           (string.gsub "\n([^\n])" " %1")
           (string.gsub "\n\n+" "\n"))))

(fn indent [n text]
  (let [margin (string.rep " " n)]
    (.. margin (string.gsub text "\n +" (.. "\n" margin )))))

(fn extract-text [description]
  (and description
;       (do (print (view description)) true)
       (-> (match description
             { :type "literalExpression" : text } text
             {} nil
             nil nil
             t description)
           strip-newlines)))

(fn print-option [o offset]
  (let [i (or offset 0)]
    (print (indent i (.. " * option ``" o.name "``")))
    (print (indent (+ 4 i)
                   (or (extract-text o.description) "(no description)")))
    (print)
    (print (indent (+ 4 i) (.. "**type** " o.type "\n")))
    (print (indent (+ 4 i)
                   (.. "**default** "
                       (or (extract-text (?. o :default)) "(none)")
                       "\n"
                       )))
    (print )))

(fn print-service [o]
  (print (.. " * service ``" o.name "``"))
  (print (indent 4 (or (extract-text o.description) "(no description)")))
  (print)
  (print (indent 4 "**Service parameters**\n"))
  (each [_ param (ipairs o.parameters)]
    (print-option param 4)))

(fn sort-options [module]
  (table.sort module (fn [a b] (< a.name b.name)))
  module)

(let [raw (yaml.load (io.read "*a"))
      modules {}]
  (each [_ option (ipairs raw)]
    (each [_ path (ipairs option.declarations)]
      (let [e (or (. modules path) [])]
        (table.insert e option)
        (tset modules path e))))
  (each [name module (pairs modules)]
    (print (read-preamble name))
    (let [options (sort-options module)]
      (each [_ o (ipairs options)]
        (if (= o.type "parametrisable s6-rc service definition")
            (print-service o)
            (print-option o))))))

;; for each element el, add to table modules keyed on
;; el.declarations

;; for each value in modules
;;   print title
;;   elements = (sort elements on el.name)
;;   for each el in elements
;;     is option or service? print whichever
;;
