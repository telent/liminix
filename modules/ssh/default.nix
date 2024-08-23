## Secure Shell
## ============
##
## Provide SSH service using Dropbear

{ lib, pkgs, config, ...}:
let
  inherit (lib) mkOption types;
  inherit (pkgs) liminix;
  mkBoolOption = description : mkOption {
    type = types.bool;
    inherit description;
    default = true;
  };

in {
  options = {
    system.service.ssh = mkOption {
      type = liminix.lib.types.serviceDefn;
    };
  };
  config.programs.busybox.options.FEATURE_FANCY_ECHO = "y";
  config.system.service = {
    ssh = config.system.callService ./ssh.nix {
      address = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Listen on specified address";
        example = "127.0.0.1";
      };
      port = mkOption {
        type = types.port;
        default = 22;
        description = "Listen on specified TCP port";
      };
      allowRoot = mkBoolOption "Allow root to login";
      allowPasswordLogin = mkBoolOption "Allow login using password (disable for public key auth only)";
      allowPasswordLoginForRoot = mkBoolOption "Allow root to login using password (disable for public key auth only)";
      allowLocalPortForward = mkBoolOption "Enable local port forwarding";
      allowRemotePortForward = mkBoolOption "Enable remote port forwarding";
      allowRemoteConnectionToForwardedPorts = mkOption {
        type = types.bool; default = false;
        description = "Allow remote hosts to connect to local forwarded ports (by default they are bound to loopback)";
      };
      authorizedKeys = mkOption {
        type = types.nullOr (types.attrsOf (types.listOf types.nonEmptyStr));
        example = {
          root = ["ssh-rsa AAAAB3N...aZaZ"];
          alice = ["ssh-rsa AAAAB3N...qS4r"];
          bob = [];
        };
        default = null;
        description = "Authorized SSH public keys for each username. If this optin is provided it overrides any keys found in /home/{username}/.ssh";
      };
      extraConfig = mkOption {
        type = types.separatedString " ";
        default = "";
      };
    };
  };
}
