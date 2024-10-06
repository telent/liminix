let
  overlay = import <liminix/overlay.nix>;
  pkgs = import <nixpkgs> { overlays = [overlay]; };
  fixture = pkgs.callPackage ./fixture.nix {};
in pkgs.runCommand "check" {
    nativeBuildInputs = with pkgs; [ squashfsTools qprint ] ;
  } ''
set -e
diff ${fixture} ${./result.expected}
test -f  /tmp/out.squashfs && rm /tmp/out.squashfs
mksquashfs - /tmp/out.squashfs -p '/ d 755 0 0' -pf ${fixture} -quiet -no-progress
foo="$(unsquashfs -cat /tmp/out.squashfs service/s6-linux-init-runleveld/run)"
test "$foo" = "$(printf "hello\nworld")"
date > $out
''
