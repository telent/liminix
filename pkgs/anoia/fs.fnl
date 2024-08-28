(local ll (require :lualinux))

(local S_IFMT   0xf000)
(local S_IFSOCK 0xc000)
(local S_IFLNK  0xa000)
(local S_IFREG  0x8000)
(local S_IFBLK  0x6000)
(local S_IFDIR  0x4000)
(local S_IFCHR  0x2000)
(local S_IFIFO  0x1000)

(macro errno-check [x]
  `(match ,x
     val# val#
     (nil errno#) (assert nil (.. "system call failed, errno=" errno#))
     ))

(fn ifmt-bits [mode] (and mode (band mode 0xf000)))

(fn file-type [pathname]
  (. {
      S_IFDIR :directory
      S_IFSOCK :socket
      S_IFLNK :link
      S_IFREG :file
      S_IFBLK :block-device
      S_IFCHR :character-device
      S_IFIFO :fifo
      }
     (ifmt-bits (ll.lstat3 pathname))))

(fn directory? [pathname]
  (= (file-type pathname) :directory))

(fn mktree [pathname]
  (if (or (= pathname "") (= pathname "/"))
      (error (.. "can't mkdir " pathname)))

  (or (directory? pathname)
      (let [parent (string.gsub pathname "/[^/]+/?$" "")]
        (or (directory? parent) (mktree parent))
        (errno-check (ll.mkdir pathname)))))

(fn dir [name]
  (let [dp (errno-check (ll.opendir name) name)]
    (fn []
      (case (ll.readdir dp)
        (name filetype) (values name filetype)
        (nil err) (do (if (> err 0) (print "ERR" err)) (ll.closedir dp) nil)
        ))))

(fn rmtree [pathname]
  (case (file-type pathname)
    nil true
    :directory
    (do
      (each [f (dir pathname)]
        (when (not (or (= f ".") (= f "..")))
          (rmtree ( .. pathname "/" f)))
        (ll.rmdir pathname)))
    :file
    (os.remove pathname)
    :link
    (os.remove pathname)
    unknown
    (error (.. "can't remove " pathname " of mode \"" unknown "\""))))

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

{
 : mktree
 : rmtree
 : directory?
 : dir
 : file-type
 : popen2
 :symlink (fn [from to] (ll.symlink from to))
 }
