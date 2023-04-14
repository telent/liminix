# The ideal is that a Liminix system can boot with only the files in
# /nix/store.  This package generates a script that is run at early
# boot (from the initramfs) to populate directories such as /etc,
# /bin, /home according to whatever the configuration says
# they should contain

{
  writeText
, runCommand
, lib
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
            chmod =
              let m = if mode != null then mode else
                    (if type == "d" then "0755" else "0644");
              in (if type == "s"
                  then ""
                  else "\nchmod ${m} ${pathname}");
            cmds = {
              "f" = "printf \"${escaped file}\" > ${pathname}";
              "d" = "mkdir ${pathname}\n"  +
                    (builtins.concatStringsSep "\n"
                      (visit pathname contents));
              "c" = "mknod ${pathname} c ${major} ${minor}";
              "b" = "mknod ${pathname} b ${major} ${minor}";
              "s" = "ln -s ${target} ${pathname}";
              "l" = "ln ${target} ${pathname}";
              "i" = "mknod ${pathname} p";
            };
            cmd = cmds.${type};
          in "${cmd}${chmod}";
    in mapAttrsToList (makeFile prefix) attrset;
  activateScript = attrset: writeText "systemConfig" ''
    #!/bin/sh
    t=$1
    ${(builtins.concatStringsSep "\n" (visit "$t" attrset))}
  '';
in attrset:
  runCommand "make-stuff" {} ''
    mkdir -p $out
    ln -s ${activateScript attrset} $out/activate
  ''
