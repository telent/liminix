{ config, lib, ... }:
let
  inherit (lib) mkIf mkEnableOption mkOption types;
in {
  options = {
    logging = {
      persistent = {
        enable = mkEnableOption "store logs across reboots";
      };
    };
  };
   config = {
     kernel.config = mkIf config.logging.persistent.enable {
       PSTORE = "y";
       PSTORE_PMSG = "y";
       PSTORE_RAM = "y";
     };
   };
}
