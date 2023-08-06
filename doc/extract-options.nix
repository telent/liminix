let
  overlay = import ../overlay.nix;
  pkgs = import <nixpkgs> ( {
    overlays = [overlay];
    config = {
      allowUnsupportedSystem = true; # mipsel
      permittedInsecurePackages = [
        "python-2.7.18.6"       # kernel backports needs python <3
      ];
    };
  });
  inherit (pkgs) lib;
  inherit (lib) types;
  modulenames =
    builtins.attrNames
      (lib.filterAttrsRecursive
        (n: t:
          (t=="directory") ||
          ((t=="regular") && ((builtins.match ".*\\.nix$" n) != null)))
        (builtins.readDir ../modules));
  modulefiles = builtins.map (n: builtins.toPath "${../modules}/${n}") modulenames;
  eval = (lib.evalModules {
    modules = [
      { _module.args = { inherit pkgs; lib = pkgs.lib; }; }
    ] ++ modulefiles;
  });
  conf = eval.config;
  optToDoc = name: opt : {
    inherit name;
    description = opt.description or null;
    default = opt.default or null;
    visible =
      if (opt ? visible && opt.visible == "shallow")
      then true
      else opt.visible or true;
    readOnly = opt.readOnly or false;
    type = opt.type.description or "unspecified";
  };
  spliceServiceDefn = item :
    if item.type == "parametrisable s6-rc service definition"
    then
      let sd = lib.attrByPath item.loc ["not found"] conf;
      in item // {
        parameters =
          let x = lib.mapAttrsToList optToDoc sd.parameters; in x;
      }
    else
      item;
  o = builtins.map spliceServiceDefn
    (pkgs.lib.optionAttrSetToDocList eval.options);
in {
  doc = pkgs.writeText "options.json"
    (builtins.unsafeDiscardStringContext (builtins.toJSON o))
  ;
}
