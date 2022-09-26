{ config, pkgs, ... }:
let
  s6-rc-db = pkgs.s6-rc-database.override {
    services = builtins.attrValues config.services;
  };
  inherit (pkgs.pseudofile) dir symlink;
in {
  config = {
    environment = dir {
      etc = dir {
        s6-rc = dir {
          compiled = symlink "${s6-rc-db}/compiled";
        };
      };
    };
  };
}
