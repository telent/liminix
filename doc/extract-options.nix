{
  eval,
  lib,
  pkgs,
}:
let
  conf = eval.config;
  rootDir = builtins.toPath ./..;
  stripAnyPrefixes = lib.flip (lib.fold lib.removePrefix) [ "${rootDir}/" ];
  optToDoc = name: opt: {
    inherit name;
    description = opt.description or null;
    default = opt.default or null;
    visible = if (opt ? visible && opt.visible == "shallow") then true else opt.visible or true;
    readOnly = opt.readOnly or false;
    type = opt.type.description or "unspecified";
  };
  spliceServiceDefn =
    item:
    if item.type == "parametrisable s6-rc service definition" then
      let
        sd = lib.attrByPath item.loc [ "not found" ] conf;
      in
      item
      // {
        declarations = map stripAnyPrefixes item.declarations;
        parameters =
          let
            x = lib.mapAttrsToList optToDoc sd.parameters;
          in
          x;
      }
    else
      item // { declarations = map stripAnyPrefixes item.declarations; };
in
builtins.map spliceServiceDefn (pkgs.lib.optionAttrSetToDocList eval.options)
