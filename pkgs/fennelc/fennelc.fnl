(local { : view &as fennel } ( require :fennel))

(fn assoc [tbl k v & more]
  (tset tbl k v)
  (case more
    [k v] (assoc tbl k v)
    _ tbl))

(fn parse-args [args]
  (case args
    ["--correlate" & rest]
    (assoc (parse-args rest)
           :correlate true)

    ["--main" main-fn & rest]
    (assoc (parse-args rest)
           :main main-fn)

    ["-o" output-file & rest]
    (assoc (parse-args rest)
           :output-file output-file)

    [source] { :source-file source }))

(fn output-name [opts]
  (or opts.output-file
      (string.gsub opts.source-file "%.fnl$" "")))

(let [luapath (os.getenv "LUA_PATH")
      luacpath (os.getenv "LUA_CPATH")
      path (os.getenv "PATH")
      opts (parse-args arg)
      output-file (output-name opts)]
  (with-open [o (io.open output-file :w)]
    (o:write "#!/usr/bin/env lua\n")
    (and luapath
         (o:write (string.format "package.path = %q .. \";\" .. package.path\n" luapath)))
    (and luacpath
         (o:write (string.format "package.cpath = %q .. \";\" .. package.cpath\n" luacpath)))
    (let [(ok? msg)
          (pcall
           fennel.compile-string
           (: (io.open opts.source-file :r) :read  "*a")
           {:filename opts.source-file
            :correlate opts.correlate})]
      (when (not ok?)
        (error (.. "error: " msg)))
      (o:write msg)
      (os.execute (string.format "chmod +x %q" output-file)))))
