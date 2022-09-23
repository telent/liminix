set -e
NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1 nix-build '<liminix>' -I liminix-config=../smoke/configuration.nix --arg device "import <liminix/devices/$DEVICE.nix>" -A outputs.kernel.vmlinux -o vmlinux $*

TESTS=$(cat <<"EOF"

trap 'echo "command $(eval echo $BASH_COMMAND) failed with exit code $?"; exit 1' ERR
test -f vmlinux
file -L vmlinux | grep ' ELF 32-bit MSB executable, MIPS'
EOF
     )


nix-shell -p s6-rc -p squashfsTools --run "$TESTS" || exit 1
