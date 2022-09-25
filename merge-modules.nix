module : initial : pkgs :
let evalModules = (import <nixpkgs/lib>).evalModules;
in evalModules {
  modules = [
    { _module.args = { inherit pkgs; }; }
    module
  ];
}
