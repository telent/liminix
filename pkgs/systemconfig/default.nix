# The ideal is that a Liminix system can boot with only the files in
# /nix/store.  This package generates a small program that is run at early
# boot (from the initramfs) to populate directories such as /etc,
# /bin, /home according to whatever the configuration says
# they should contain

{
  writeText
, lib
, s6-init-bin
, closureInfo
, stdenv
}:
let
  inherit (lib.attrsets) mapAttrsToList;
  escaped = msg : builtins.replaceStrings
    ["\n"  "="   "\""  "$"  ]
    ["\\x0a" "\\x3d" "\\x22" "\\x24"]
    msg;

  visit = prefix: attrset:
    let makeFile = prefix : filename: {
          type ? "f"
          , mode ? null
          , target ? null
          , contents ? null
          , file ? null
          , major ? null
          , minor ? null
          , uid ? 0
          , gid ? 0
        }:
          let
            pathname = "${prefix}/${filename}";
            qpathname = builtins.toJSON pathname;
            mode' = if mode != null
                    then mode
                    else
                      (if type == "d" then "0755" else "0644");
            cmds = {
              "f" = "PRINTFILE(${qpathname}, ${mode'}, ${builtins.toJSON (escaped file)});";
              "d" = "MKDIR(${qpathname}, ${mode'});\n"  +
                    (builtins.concatStringsSep "\n"
                      (visit pathname contents));
              "c" = "MKNOD_C(${qpathname}, ${mode'}, ${major}, ${minor});";
              "b" = "MKNOD_B(${qpathname}, ${mode'}, ${major}, ${minor});";
              "s" = "LN_S(${builtins.toJSON target}, ${qpathname});";
              "l" = "LN(${builtins.toJSON target}, ${qpathname})";
              "i" = "MKNOD_P(${qpathname}, ${mode'});";
            };
            cmd = cmds.${type};
            chown = if uid>0 || gid>0
                    then "\nCHOWN(${qpathname},${toString uid},${toString gid});\n"
                    else "";
          in "${cmd} ${chown}";
    in mapAttrsToList (makeFile prefix) attrset;
  activateScript = attrset: writeText "makedevs.c" ''
    #include "defs.h"
    int main(int argc, char* argv[]) {
      chdir(argv[1]);
      ${(builtins.concatStringsSep "\n" (visit "." attrset))}
    }
  '';
in attrset:
  let makedevs = activateScript attrset;
  in stdenv.mkDerivation {
    name="make-stuff";
    src = ./.;

    CFLAGS = "-Os";
    LDFLAGS  = "-static -Xlinker -static";

    postConfigure = ''
      cp ${makedevs} makedevs.c
    '';
    makeFlags = ["makedevs"];
    installPhase = ''
      closure=${closureInfo { rootPaths = [ makedevs ]; }}
      mkdir -p $out/bin $out/etc
      cp $closure/store-paths $out/etc/nix-store-paths
      $STRIP --remove-section=.note  --remove-section=.comment --strip-all makedevs -o $out/bin/activate
      ln -s ${s6-init-bin}/bin/init $out/bin/init
    '';
  }
