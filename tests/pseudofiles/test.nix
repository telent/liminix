let
  overlay = import <liminix/overlay.nix>;
  nixpkgs = import <nixpkgs> { overlays = [overlay]; };
  fixture = nixpkgs.callPackage ./fixture.nix {};
in nixpkgs.runCommand "check" {
    nativeBuildInputs = with <nixpkgs>; [ squashfsTools qprint ] ;
  } ''
set -e
diff ${fixture} ${./result.expected}
test -f  /tmp/out.squashfs && rm /tmp/out.squashfs
mksquashfs - /tmp/out.squashfs -p '/ d 755 0 0' -pf ${fixture} -quiet -no-progress
foo="$(unsquashfs -cat /tmp/out.squashfs service/s6-linux-init-runleveld/run)"
test "$foo" = "$(printf "hello\nworld")"
date > $out
''
