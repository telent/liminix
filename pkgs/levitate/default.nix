{
  writeScriptBin
, writeScript
, systemconfig
, execline
, lib
, config ? {}
, liminix
, pseudofile
, pkgs
} :
let
  inherit (pseudofile) dir symlink;
  inherit (liminix.services) oneshot;
  paramConfig = config;
  newRoot = "/run/maintenance";
  sysconfig =
    let
      doChroot =  writeScript "exec" ''
        #!${execline}/bin/execlineb -P
        cd ${newRoot}
        foreground { mount --move ${newRoot} / }
        redirfd -r 0 /dev/console
        redirfd -w 1 /dev/console
        fdmove -c 2 1
        emptyenv chroot . /bin/init
      '';
      base = {...} : {
        config =  {
          services = {
            banner = oneshot {
              name = "banner";
              up = "cat /etc/banner > /dev/console";
              down = "true";
            };
          };

          filesystem = dir {
            exec = symlink doChroot;
            etc = dir {
              banner = symlink (pkgs.writeText "banner" ''

                LADIES AND GENTLEMEN WE ARE FLOATING IN SPACE

                Most services are disabled. The system is operating
                with a ram-based root filesystem, making it safe to
                overwrite the flash devices in order to perform
                upgrades and maintenance.

                Don't forget to reboot when you have finished.

              '');
            };
          };
        };
      };
      eval = lib.evalModules {
        modules = [
          { _module.args = { inherit pkgs; inherit (pkgs) lim; }; }
          ../../modules/base.nix
          ../../modules/users.nix
          ../../modules/busybox.nix
          base
          ({ ... } : paramConfig)
          ../../modules/s6
        ];
      };
    in systemconfig eval.config.filesystem.contents;
in writeScriptBin "levitate"  ''
  #!/bin/sh
  destdir=${newRoot}
  mkdir -p $destdir $destdir/nix/store
  for path in $(cat ${sysconfig}/etc/nix-store-paths) ; do
    (cd $destdir && cp -a $path .$path)
  done
  ${sysconfig}/bin/activate $destdir
''
