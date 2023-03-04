{
  writeText
, lib
}:
let
  inherit (lib.attrsets) mapAttrsToList;
  visit = prefix: attrset:
    let
      qprint = msg : builtins.replaceStrings
        ["\n" "=" "\"" "$"] ["=0A" "=3D" "=22" "=24"] msg;
      l =
        mapAttrsToList
          (filename: attrs:
            let
              attrs' = {type = "f"; } // attrs;
              mode = if attrs ? mode then attrs.mode else
                (if attrs'.type == "d" then "0755" else "0644");
              line = "${prefix}/${filename} ${attrs'.type} ${mode} 0 0";
            in
              if attrs'.type == "f" then
                "${line} echo -n \"${qprint attrs'.file}\" |qprint -d"
              else if attrs'.type == "d" then
                (visit "${prefix}/${filename}" attrs.contents) +
                "\n" + line
              else if attrs'.type == "c" then
                with attrs'; "${line} ${major} ${minor}"
              else if attrs'.type == "b" then
                with attrs'; "${line} ${major} ${minor}"
              else if attrs'.type == "s" then
                "${line} ${attrs'.target}"
              else if attrs'.type == "l" then
                "${prefix}/${filename} l ${attrs'.target}"
              else if attrs'.type == "i" then
                "${line} ${attrs.subtype}"
              else
                line)
          attrset;
    in builtins.concatStringsSep "\n" l;
in {
  write = filename : attrset : writeText filename (visit "" attrset);
  dir = contents: { type = "d"; inherit contents; };
  symlink = target: { type = "s"; inherit target; };
}
