(local up-tree (require "s6-rc-up-tree"))

(os.remove (os.getenv "TEST_LOG"))

(let [[dir & services] arg]
  (set arg services)
  (up-tree.run dir))

;; the service starts
;; the service starts even if it is controlled
;; uncontrolled descendants start
;; controlled descendants don't start
;; descendants which depend on a _different_ controlled service, which is down, don't start
;; descendants which depend on a _different_ controlled service, which is up, do start
