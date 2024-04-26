{ nixpkgs ? <nixpkgs>, pkgs ? (import <nixpkgs> {}), lib ? pkgs.lib }:
args:
let
  modulesPath = builtins.toString ../modules;
in
# FIXME: we could replace the `lib` by a lib-only minimal nixpkgs.
(import "${nixpkgs}/lib/modules.nix" { inherit lib; }).evalModules (args // {
  specialArgs = (args.specialArgs or {}) // {
    inherit modulesPath;
  };
  modules = (args.modules or []) ++ [
    "${modulesPath}/hardware.nix"
    "${modulesPath}/base.nix"
    "${modulesPath}/busybox.nix"
    "${modulesPath}/hostname.nix"
    "${modulesPath}/s6"
    "${modulesPath}/users.nix"
    "${modulesPath}/outputs.nix"
    # FIXME: we should let the caller inject `pkgs` and `lim` ideally...
  ] ++ lib.optional (pkgs ? lim) {
    _module.args = { inherit (pkgs) lim; };
  };
})
