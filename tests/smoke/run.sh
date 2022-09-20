set -e
NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1 nix-build  -I liminix-config=./tests/smoke/configuration.nix --arg device "import ./devices/$DEVICE.nix" -o smoke.img

TESTS=$(cat <<"EOF"

trap 'echo "command $(eval echo $BASH_COMMAND) failed with exit code $?"; exit $?' ERR
dest_path=${TMPDIR}/smoke.img-$$
echo $dest_path
unsquashfs -q -d $dest_path smoke.img
cd $dest_path;
db=*-s6-rc-db/compiled/
test -d $db
chmod -R +w $db
# check we have closure of config.services (lo.link.service exists only
# as a dependency)
test "$(s6-rc-db -c $db type lo.link.service)" = "oneshot"
test "$(s6-rc-db -c $db type ntp.service)" = "longrun"
echo OK
EOF
     )


nix-shell -p s6-rc -p squashfsTools --run "$TESTS" || exit 1
