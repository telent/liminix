{
  config
, pkgs
, lib
, ...
}:
let
  inherit (lib) mkOption types concatStringsSep;
  inherit (pkgs) liminix callPackage writeText closureInfo;
in
{
  imports = [
    ./initramfs.nix
  ];
  config = {
    kernel.config.JFFS2_FS = "y";
    outputs = rec {
      systemConfiguration =
        let inherit (pkgs.pkgsBuildBuild) systemconfig;
        in systemconfig config.filesystem.contents;
      jffs2fs =
        let
          inherit (pkgs.pkgsBuildBuild) runCommand systemconfig mtdutils;
          sysconf = systemConfiguration;
        in runCommand "make-jffs2" {
          depsBuildBuild = [ mtdutils ];
        } ''
          mkdir -p $TMPDIR/empty/nix/store/
          cp ${sysconf}/activate  $TMPDIR/empty/activate
          pkgClosure=${closureInfo { rootPaths = [ sysconf ]; }}
          cp $pkgClosure/registration nix-path-registration
          grafts=$(sed < $pkgClosure/store-paths 's/^\(.*\)$/--graft \1:\1/g')
          mkfs.jffs2 --pad  --big-endian --root $TMPDIR/empty --output $out  $grafts  --verbose
        '';
      jffs2boot =
        let o = config.outputs; in
        pkgs.runCommand "jffs2boot" {} ''
          mkdir $out
          cd $out
          ln -s ${o.jffs2fs} rootfs
          ln -s ${o.kernel} vmlinux
          ln -s ${o.manifest} manifest
          ln -s ${o.initramfs} initramfs
       '';


    };
  };
}
