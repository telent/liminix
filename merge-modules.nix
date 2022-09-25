modules : pkgs :
let evalModules = (import <nixpkgs/lib>).evalModules;
in (evalModules {
  modules =
    [
      { _module.args = { inherit pkgs; lib = pkgs.lib; }; }
    ] ++ modules;
}).config
