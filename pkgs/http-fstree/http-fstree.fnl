(local json (require :json))
(local http (require :fetch))
(local svc (require :anoia.svc))
(local { : utime } (require :lualinux))

(fn download [url dest]
  (match (http.fetch url)
    (nil code str)
    (assert nil (.. "error " code ": " str))

    (body { : last-modified })
    (let [service (svc.open dest)]
      (service:output "." (json.decode body))
      (utime dest last-modified))))

(fn run [] (download (. arg 1) (. arg 2)))


{ : run }
