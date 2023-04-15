{
  config
, pkgs
, lib
, ...
}:
let
  inherit (pkgs) closureInfo;
  inherit (lib) mkIf;
in
{
  imports = [
    ./initramfs.nix
  ];
  config = mkIf (config.rootfsType == "jffs2") {
    kernel.config.JFFS2_FS = "y";
    boot.initramfs.enable = true;
    outputs = rec {
      systemConfiguration =
        pkgs.systemconfig config.filesystem.contents;
      rootfs =
        let
          inherit (pkgs.pkgsBuildBuild) runCommand mtdutils;
          endian = if pkgs.stdenv.isBigEndian
                   then "--big-endian" else "--little-endian";
        in runCommand "make-jffs2" {
          depsBuildBuild = [ mtdutils ];
        } ''
          mkdir -p $TMPDIR/empty/nix/store/
          cp ${systemConfiguration}/bin/activate $TMPDIR/empty/activate
          ln -s ${pkgs.s6-init-bin}/bin/init $TMPDIR/empty/init
          pkgClosure=${closureInfo {
             rootPaths = [ systemConfiguration ];
           }}
          cp $pkgClosure/registration nix-path-registration
          grafts=$(sed < $pkgClosure/store-paths 's/^\(.*\)$/--graft \1:\1/g')
          mkfs.jffs2 ${endian} -e ${config.hardware.flash.eraseBlockSize} --pad --root $TMPDIR/empty --output $out  $grafts
        '';
      jffs2boot =
        let o = config.outputs; in
        pkgs.runCommand "jffs2boot" {} ''
          mkdir $out
          cd $out
          ln -s ${o.rootfs} rootfs
          ln -s ${o.kernel} vmlinux
          ln -s ${o.manifest} manifest
          ln -s ${o.initramfs} initramfs
       '';
    };
  };
}
