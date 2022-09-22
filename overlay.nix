final: prev: {
  pseudofile = final.callPackage ./pkgs/pseudofile {};
  s6-init-files = final.callPackage ./pkgs/s6-init-files {};
  strace = prev.strace.override { libunwind = null; };
  liminix = final.callPackage ./pkgs/liminix-tools {};
}
