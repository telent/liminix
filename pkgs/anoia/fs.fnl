(local ll (require :lualinux))

(local S_IFMT   0xf000)
(local S_IFSOCK 0xc000)
(local S_IFLNK  0xa000)
(local S_IFREG  0x8000)
(local S_IFBLK  0x6000)
(local S_IFDIR  0x4000)
(local S_IFCHR  0x2000)
(local S_IFIFO  0x1000)

(fn ifmt-bits [mode] (and mode (band mode 0xf000)))

(fn directory? [pathname]
  (let [(mode size mtime) (ll.lstat3 pathname)]
    (= (ifmt-bits mode) S_IFDIR)))

(fn mktree [pathname]
  (if (or (= pathname "") (= pathname "/"))
      (error (.. "can't mkdir " pathname)))

  (or (directory? pathname)
      (let [parent (string.gsub pathname "/[^/]+/?$" "")]
        (or (directory? parent) (mktree parent))
        (assert (ll.mkdir pathname)))))

(fn rmtree [pathname]
  (case (ifmt-bits (ll.lstat3 pathname))
    nil true
    S_IFDIR
    (do
      (each [f (lfs.dir pathname)]
        (when (not (or (= f ".") (= f "..")))
          (rmtree ( .. pathname "/" f)))
        (lfs.rmdir pathname)))
    S_IFREG
    (os.remove pathname)
    S_IFLNK
    (os.remove pathname)
    unknown
    (error (.. "can't remove " pathname " of mode \"" unknown "\""))))


{
 : mktree
 : rmtree
 : directory?
 :symlink (fn [from to] (ll.symlink from to))
 }
