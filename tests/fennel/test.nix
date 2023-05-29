{
  liminix
, nixpkgs
}:
let
  overlay = import "${liminix}/overlay.nix";
  pkgs = import <nixpkgs> { overlays = [overlay]; };
  script = pkgs.writeFennelScript "foo" [] ./hello.fnl;
  inherit (pkgs.luaSmall.pkgs) fifo;
  netlink = pkgs.netlink-lua.override { lua = pkgs.luaSmall; };
  script2 = pkgs.writeFennelScript "foo2" [fifo netlink] ./hello.fnl;
in pkgs.runCommand "check" {
  } ''
set -e
# test that it works
test $(${script}) = "hello"
# test that lua path, cpath are set
grep -q ${fifo}/share/lua/5.3 ${script2}
grep -q ${netlink}/lib/lua/5.3 ${script2}
date > $out
''
