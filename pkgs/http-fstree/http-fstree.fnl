(local json (require :json))
(local http (require :fetch))
(local svc (require :anoia.svc))
(local { : utime } (require :lualinux))

(fn download [url dest]
  (match (http.fetch url)
    (nil code str)
    (assert nil (.. "error " code ": " str))

    (body { : last-modified })
    (let [service (svc.open dest)
          lock (.. dest "/.lock")
          state (.. dest "/state")]
      (with-open [fout (io.open lock :w)] (fout:write ""))
      (service:output "." (json.decode body))
      (with-open [fout (io.open state :w)] (fout:write "ok"))
      (os.remove lock)
      (utime dest last-modified))))

(fn run [] (download (. arg 1) (. arg 2)))


{ : run }
