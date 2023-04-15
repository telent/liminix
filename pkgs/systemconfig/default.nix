# The ideal is that a Liminix system can boot with only the files in
# /nix/store.  This package generates a small program that is run at early
# boot (from the initramfs) to populate directories such as /etc,
# /bin, /home according to whatever the configuration says
# they should contain

{
  writeText
, lib
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
          assert uid == 0;
          assert gid == 0;
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
          in "${cmd}";
    in mapAttrsToList (makeFile prefix) attrset;
  activateScript = attrset: writeText "makedevs.c" ''
    #include "defs.h"
    int main(int argc, char* argv[]) {
      chdir(argv[1]);
      ${(builtins.concatStringsSep "\n" (visit "." attrset))}
    }
  '';
in attrset:
  stdenv.mkDerivation {
    name="make-stuff";
    src = ./.;

    CFLAGS = "-Os";
    LDFLAGS  = "-static";

    postConfigure = ''
      cp ${activateScript attrset} makedevs.c
    '';
    makeFlags = ["makedevs"];
    installPhase = ''
      mkdir -p $out/bin
      $STRIP --remove-section=.note --remove-section=.comment --strip-all makedevs -o $out/bin/activate
    '';
  }
