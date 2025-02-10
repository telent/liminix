let
  pkgs = import <nixpkgs> { overlays = [ (import ../../overlay.nix) ]; };
  ruleset = import ./test-rules-min.nix;
in
pkgs.firewallgen "firewall.nft" ruleset
