(local json (require :json))
(local http (require :fetch))
(local svc (require :anoia.svc))
(local { : utime } (require :lualinux))

(fn download [url dest]
  (let [state (.. dest "/state")
        previously (ll.lstat state 12)]
    (match (http.fetch url "i" previously)
      (nil 10 _) ; not modified
      (print (.. url " not modified, already up to date"))

      (nil code str)
      (assert nil (.. "error " code ": " str))

      (body { : last-modified })
      (let [service (svc.open dest)
            lock (.. dest "/.lock")]
        (with-open [fout (io.open lock :w)] (fout:write ""))
        (service:output "." (json.decode body))
        (with-open [fout (io.open state :w)] (fout:write "ok"))
        (utime state last-modified)
        (os.remove lock))

      )))

(fn run [] (download (. arg 1) (. arg 2)))


{ : run }
