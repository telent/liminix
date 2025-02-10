# The ideal is that a Liminix system can boot with only the files in
# /nix/store.  This package generates a small program that is run at early
# boot (from the initramfs) to populate directories such as /etc,
# /bin, /home according to whatever the configuration says
# they should contain

{
  writeText,
  writeFennel,
  buildPackages,
  lib,
  s6-init-bin,
  closureInfo,
  stdenv,
}:
let
  inherit (lib.attrsets) mapAttrsToList;
  escaped =
    msg: builtins.replaceStrings [ "\n" "=" "\"" "$" ] [ "\\x0a" "\\x3d" "\\x22" "\\x24" ] msg;

  visit =
    prefix: attrset:
    let
      makeFile =
        prefix: filename:
        {
          type ? "f",
          mode ? null,
          target ? null,
          contents ? null,
          file ? null,
          major ? null,
          minor ? null,
          uid ? 0,
          gid ? 0,
        }:
        let
          pathname = "${prefix}/${filename}";
          qpathname = builtins.toJSON pathname;
          mode' = if mode != null then mode else (if type == "d" then "0755" else "0644");
          cmds = {
            "f" = "PRINTFILE(${qpathname}, ${mode'}, ${builtins.toJSON (escaped file)});";
            "d" =
              "MKDIR(${qpathname}, ${mode'});\n" + (builtins.concatStringsSep "\n" (visit pathname contents));
            "c" = "MKNOD_C(${qpathname}, ${mode'}, ${major}, ${minor});";
            "b" = "MKNOD_B(${qpathname}, ${mode'}, ${major}, ${minor});";
            "s" = "LN_S(${builtins.toJSON target}, ${qpathname});";
            "l" = "LN(${builtins.toJSON target}, ${qpathname})";
            "i" = "MKNOD_P(${qpathname}, ${mode'});";
          };
          cmd = cmds.${type};
          chown =
            if uid > 0 || gid > 0 then "\nCHOWN(${qpathname},${toString uid},${toString gid});\n" else "";
        in
        "unlink(${qpathname}); ${cmd} ${chown}";
    in
    mapAttrsToList (makeFile prefix) attrset;
in
attrset:
let
  activateScript = writeText "activate.c" ''
    #include "defs.h"
    int main(int argc, char* argv[]) {
      chdir(argv[1]);
      ${(builtins.concatStringsSep "\n" (visit "." attrset))}
    }
  '';
in
stdenv.mkDerivation {
  name = "system-configuration";
  src = ./.;

  CFLAGS = "-Os";
  LDFLAGS = "-static -Xlinker -static";

  postConfigure = ''
    cp ${activateScript} activate.c
  '';
  makeFlags = [ "activate" ];
  installPhase = ''
    closure=${closureInfo { rootPaths = [ activateScript ]; }}
    mkdir -p $out/bin $out/etc
    cp $closure/store-paths $out/etc/nix-store-paths
    $STRIP --remove-section=.note  --remove-section=.comment --strip-all activate -o $out/bin/activate
    ln -s ${s6-init-bin}/bin/init $out/bin/init
    cp -p ${writeFennel "restart-services" { } ./restart-services.fnl} $out/bin/restart-services
    cat > $out/bin/install <<EOF
    #!/bin/sh -e
    prefix=\''${1-/}
    src=\''${prefix}$out
    dest=\$prefix
    ${
      # if we are running on a normal mounted system then
      # the actual device root is mounted on /persist
      # and /nix is bind mounted from /persist/nix
      # (see the code in preinit). So we need to check for this
      # case otherwise we will install into a ramfs/rootfs
      ""
    }
    if test -d \$dest/persist; then dest=\$dest/persist; fi
    cp -v -fP \$src/bin/* \$src/etc/* \$dest
    ${
      if attrset ? boot then
        ''
          (cd \$dest
           test -d boot || mkdir boot
           cd boot
           cp ../${lib.strings.removePrefix "/" attrset.boot.target}/* .
           sync; sync
          )
        ''
      else
        ""
    }
    EOF
    chmod +x $out/bin/install
  '';
}
