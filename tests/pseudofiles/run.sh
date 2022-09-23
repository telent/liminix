set -e

expr=$(cat <<"EXPR"
let
  overlay = import <liminix/overlay.nix>;
  nixpkgs = import <nixpkgs> { overlays = [overlay]; };
  structure = import ./structure.nix;
in nixpkgs.pkgs.pseudofile "pseudo.s6-init" structure
EXPR
    )

NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1 nix-build -E "${expr}" -o result $*
diff result result.expected
test -f  /tmp/out.squashfs && rm /tmp/out.squashfs
nix-shell -p squashfsTools -p qprint --run "mksquashfs - /tmp/out.squashfs -p '/ d 755 0 0' -pf result -quiet -no-progress"
foo="$(nix-shell -p squashfsTools --run 'unsquashfs -cat /tmp/out.squashfs service/s6-linux-init-runleveld/run')"
test "$foo" = "$(printf "hello\nworld")"
