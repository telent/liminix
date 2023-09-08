(local lfs (require :lfs))

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


{ : rmtree }
