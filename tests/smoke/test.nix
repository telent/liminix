let
  img =
    (import <liminix> {
      device = import <liminix/devices/qemu>;
      liminix-config = { ... }:
        {
          imports = [ <liminix/vanilla-configuration.nix> ];
          config.hosts = {
            "127.0.0.53" = [ "apple" "orange" ];
          };
        };
    }).outputs.rootfs;
  pkgs = import <nixpkgs> { };
in
pkgs.runCommand "check"
  {
    nativeBuildInputs = with pkgs; [
      squashfsTools
      s6-rc
    ];
  }
  ''
    destpath=$(mktemp -d)/smoke.img
    echo $destpath
    cleanup(){  test -n $destpath && test -d $destpath && chmod -R +w $destpath && rm -rf $destpath;  }
    trap cleanup EXIT
    trap 'echo "command $(eval echo $BASH_COMMAND) failed with exit code $?"; exit $?' ERR
    unsquashfs -q -d $destpath -excludes ${img}  /dev
    cd $destpath;
    hostsfile=$(echo $(readlink etc/hosts) | sed 's/^.//')
    grep -q -E '127.0.0.1.+localhost' $hostsfile
    grep -q -E '127.0.0.53.+apple.+orange' $hostsfile
    db=nix/store/*-s6-rc-database/compiled/
    test -d $db
    chmod -R +w $db
    # check we have closure of config.services (lo.link service exists only
    # as a dependency)
    test "$(s6-rc-db -c $db type lo.link)" = "oneshot"
    test "$(s6-rc-db -c $db type ntp)" = "longrun"
    echo OK > $out
  ''
