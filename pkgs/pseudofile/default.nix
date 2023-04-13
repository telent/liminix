{
  writeText
, lib
}:
let
  inherit (lib.attrsets) mapAttrsToList;
  visit = prefix: attrset:
    let
      qprint = msg : builtins.replaceStrings
        ["\n"  "="   "\""  "$"  ]
        ["=0A" "=3D" "=22" "=24"]
        msg;
      l =
        mapAttrsToList
          (filename: {
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
              mode' = if mode != null then mode else
                (if type == "d" then "0755" else "0644");
              pathname = "${prefix}/${filename}";
              line = "${pathname} ${type} ${mode'} ${toString uid} ${toString gid}";
            in
              if type == "f" then
                "${line} echo -n \"${qprint file}\" |qprint -d"
              else if type == "d" then
                (visit pathname contents) + "\n" + line
              else if type == "c" then "${line} ${major} ${minor}"
              else if type == "b" then "${line} ${major} ${minor}"
              else if type == "s" then "${line} ${target}"
              else if type == "l" then "${pathname} l ${target}"
              else if type == "i" then "${line} f"
              else line)
          attrset;
    in builtins.concatStringsSep "\n" l;
in {
  write = filename : attrset : writeText filename (visit "" attrset);
  dir = contents: { type = "d"; inherit contents; };
  symlink = target: { type = "s"; inherit target; };
}
