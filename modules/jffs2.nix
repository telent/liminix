{
  config
, pkgs
, ...
}:
let
  inherit (pkgs) closureInfo;
in
{
  imports = [
    ./initramfs.nix
  ];
  config = {
    kernel.config.JFFS2_FS = "y";
    outputs = rec {
      systemConfiguration =
        pkgs.pkgsBuildBuild.systemconfig config.filesystem.contents;
      jffs2fs =
        let
          inherit (pkgs.pkgsBuildBuild) runCommand mtdutils;
          endian = if pkgs.stdenv.isBigEndian
                   then "--big-endian" else "--little-endian";
        in runCommand "make-jffs2" {
          depsBuildBuild = [ mtdutils ];
        } ''
          mkdir -p $TMPDIR/empty/nix/store/
          cp ${systemConfiguration}/activate  $TMPDIR/empty/activate
          pkgClosure=${closureInfo {
             rootPaths = [ systemConfiguration ];
           }}
          cp $pkgClosure/registration nix-path-registration
          grafts=$(sed < $pkgClosure/store-paths 's/^\(.*\)$/--graft \1:\1/g')
          mkfs.jffs2 ${endian} --pad --root $TMPDIR/empty --output $out  $grafts
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
