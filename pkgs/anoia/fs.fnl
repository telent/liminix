(local lfs (require :lfs))

(fn directory? [pathname]
  (= (lfs.symlinkattributes pathname :mode) "directory"))

(fn mktree [pathname]
  (if (or (= pathname "") (= pathname "/"))
      (error (.. "can't mkdir " pathname)))

  (or (directory? pathname)
      (let [parent (string.gsub pathname "/[^/]+/?$" "")]
        (or (directory? parent) (mktree parent))
        (assert (lfs.mkdir pathname)))))

(fn rmtree [pathname]
  (case (lfs.symlinkattributes pathname)
    nil true
    {:mode "directory"}
    (do
      (each [f (lfs.dir pathname)]
        (when (not (or (= f ".") (= f "..")))
          (rmtree ( .. pathname "/" f)))
        (lfs.rmdir pathname)))
    {:mode "file"}
    (os.remove pathname)
    {:mode "link"}
    (os.remove pathname)
    unknown
    (error (.. "can't remove " pathname " of kind \"" unknown.mode "\""))))


{
 : mktree
 : rmtree
 : directory?
 :symlink (fn [from to] (lfs.link from to true))
 }
