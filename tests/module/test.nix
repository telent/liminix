{ device }:
let
  overlay = import <liminix/overlay.nix> ;
  nixpkgs = import <nixpkgs> ( device.system // {overlays = [overlay]; });
  inherit (nixpkgs) lib pkgs;
  inherit (lib.asserts) assertMsg;
  config =
    (import <liminix/merge-modules.nix>) ./configuration.nix {} pkgs;
  res1 = assertMsg
    # check we have packages from both modules
    (config.config.systemPackages == ( with pkgs; [ units hello ])) "failed";
  res2 = let s = config.config.services;
         in assertMsg (s.a.enable && s.b.enable && (s.z != null) ) "failed";
in pkgs.writeText "foo" ''
   ${if res1 then "OK" else "not OK"}
   ${if res2 then "OK" else "not OK"}
''
