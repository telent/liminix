set -e
NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1 nix-build --arg device "import <liminix/devices/qemu.nix>" test.nix
