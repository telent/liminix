(local ll (require :lualinux))
(local { : find-executable } (require :anoia.fs))
(import-macros { : define-tests : expect : expect= } :anoia.assert)

(macro errno-check [x]
  `(match ,x
     val# val#
     (nil errno#) (assert nil (.. "system call failed, errno=" errno#))
     ))

(fn popen2 [pname argv envp]
  (case (ll.pipe2)
    (cin-s cin-d)
    (match (ll.pipe2)
      (cout-s cout-d)
      (let [(pid err) (ll.fork)]
        (if (not pid) (error (.. "error: " err))
            (= pid 0)
            (do
              (ll.close cin-d)
              (ll.close cout-s)
              (ll.dup2 cin-s 0)
              (ll.dup2 cout-d 1)
              (ll.dup2 cout-d 2)
              (ll.execve pname argv envp)
              (error "execve failed"))
            (> pid 0)
            (do
              (ll.close cin-s)
              (ll.close cout-d)))
        (values pid cin-d cout-s))
      (nil err) (error (.. "popen pipe out: " err)))
    (nil err) (error (.. "popen pipe in: " err))))

(fn spawn [pname argv envp callback]
  (let [(pid in out) (popen2 pname argv envp)
        pollfds [
                 (bor (lshift in 32) (lshift 4 16))
                 (bor (lshift out 32) (lshift 1 16))
                 ]]
    (while (or (> (. pollfds 1) 0) (> (. pollfds 2) 0))
      (ll.poll pollfds)
      (if
       (> (band (. pollfds 2) 0x11) 0)  ; POLLIN | POLLHUP
       (if (not (callback :out out)) (tset pollfds 2 (lshift -1 32)))

       (> (band (. pollfds 1) 4) 0)     ; POLLOUT
       (if (not (callback :in in)) (tset pollfds 1 (lshift -1 32)))
       ))

    (match (ll.waitpid pid)
      (0 status) false
      (pid status) (rshift (band status 0xff00) 8)
      (nil errno) (error (.. "waitpid: " errno)))))


(define-tests
  (var buf "4 * 6\n")                   ;; spawn bc to multiply two numbers
  (let [out []
        p (spawn
           (assert (find-executable "bc" (os.getenv "PATH")))
           ["bc"]
           (ll.environ)
           (fn [stream fd]
             (match stream
               :out (let [b (ll.read fd)]
                      (table.insert out b)
                      (> (# b) 0))
               :in (if (> (# buf) 0)
                       (let [bytes (ll.write fd buf)]
                         (set buf (string.sub buf (+ bytes 1) -1))
                         true)
                       (do
                         (ll.close fd)
                         false))
               :err (assert nil (ll.read fd)))))]
    (expect= (table.concat out) "24\n"))
  )


{
 : popen2
 : spawn
 }
