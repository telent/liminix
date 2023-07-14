{ lib, pkgs, config, ...}:
let
  inherit (lib) mkEnableOption mkOption types isDerivation hasAttr ;
  inherit (pkgs.pseudofile) dir symlink;
  inherit (pkgs) stdenv wireless-regdb;
in {
  options = {
    system.service.pppoe = mkOption {
      type = types.functionTo types.package;
    };
  };
  config = {
    system.service.pppoe = pkgs.liminix.networking.pppoe;
    kernel = {
      config = {
        PPP = "y";
        PPP_BSDCOMP = "y";
        PPP_DEFLATE = "y";
        PPP_ASYNC = "y";
        PPP_SYNC_TTY = "y";
      };
    };
  };
}
