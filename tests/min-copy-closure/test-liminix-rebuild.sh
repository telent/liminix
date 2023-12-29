# This is a test for liminix-rebuild. It's not a CI test because
# liminix-rebuild calls nix-build so won't run inside a derivation,
# meaning you have to remember to run it manually when changing
# liminix-rebuild

# nix-shell -p  expect socat --run "sh ./tests/min-copy-closure/test-liminix-rebuild.sh "

. tests/test-helpers.sh

set -e

here=$(pwd)/tests/min-copy-closure
top=$(pwd)

work=$(mktemp -d -t "test-lim-rebuild-XXXXXX")
echo $work
cd $work

deriv(){
    (cd $top && nix-build -I liminix-config=${here}/config-ext4.nix  --arg device "import ./devices/qemu-armv7l" -A $1 );
}

PATH=$(deriv pkgs.pkgsBuildBuild.min-copy-closure)/bin:$(deriv pkgs.pkgsBuildBuild.run-liminix-vm)/bin:$PATH

rootfs=$(deriv outputs.rootfs)
kernel=$(deriv outputs.zimage)
uboot=$(deriv outputs.u-boot)

test -d ./vm && rm -rf vm
mkdir ./vm

cat ${rootfs} > rootfs

truncate -s 24M rootfs
resize2fs rootfs

dd if=rootfs of=disk-image bs=512 seek=4 conv=sync
echo '4,-,L,*' | sfdisk disk-image

run-liminix-vm --background vm  \
	       --command-line "console=ttyAMA0 panic=10 oops=panic loglevel=8 root=/dev/vda1 rootfstype=ext4" \
	       --phram-address 0x50000000 --arch arm \
	       --lan "user,hostfwd=tcp::2022-:22" \
	       --flag -append --flag "root=/dev/vda1" --flag -hda \
	       --flag disk-image $kernel /dev/null

expect ${here}/wait-until-ready.expect
echo "READY"

touch known_hosts
export SSH_COMMAND="ssh -o UserKnownHostsFile=${work}/known_hosts -o StrictHostKeyChecking=no -p 2022 -i ${here}/id"

(cd ${top} && liminix-rebuild root@localhost -I liminix-config=${here}/with-figlet.nix  --arg device "import ./devices/qemu-armv7l")

ls -l vm

cd ${work} && expect $here/wait-for-reboot.expect
cd / ; rm -rf $work
