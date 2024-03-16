## Base options
## ============


{ lib, pkgs, config, ...}:
let
  inherit (lib) mkEnableOption mkOption types isDerivation hasAttr ;
  inherit (pkgs.pseudofile) dir symlink;
  inherit (pkgs.liminix.networking) address interface;
  inherit (pkgs.liminix.services) bundle;

  type_service = pkgs.liminix.lib.types.service;

in {
  imports = [
    ./kernel            # kernel is a separate module for doc purposes
  ];
  options = {
    defaultProfile = {
      packages = mkOption {
        type = types.listOf types.package;
        description = ''
          List of packages which are available in a login shell. (This
          is analogous to systemPackages in NixOS, but we don't symlink into
          /run/current-system, we just add the paths in /etc/profile
        '';
      };
    };
    services = mkOption {
      type = types.attrsOf type_service;
    };
    system.callService = mkOption {
      type = types.functionTo (types.functionTo types.anything);
    };

    filesystem = mkOption {
      type = types.anything;
      description = ''
        Skeleton filesystem, represented as nested attrset. Consult the
        source code if you need to add to this
      '';
      # internal = true;  # probably a good case to make this internal
    };
    rootfsType =  mkOption {
      default = "squashfs";
      type = types.enum [
        "btrfs"
        "ext4"
        "jffs2"
        "squashfs"
        "ubifs"
      ];
    };
    rootOptions =  mkOption {
      type = types.nullOr types.str;
      default = null;
    };

    boot = {
      commandLine = mkOption {
        type = types.listOf types.nonEmptyStr;
        default = [];
        description = "Kernel command line";
      };
      commandLineDtbNode = mkOption {
        type = types.enum [ "bootargs" "bootargs-override" ];
        default = "bootargs";
        description = "Kernel command line's devicetree node";
      };
      imageType = mkOption {
        type = types.enum [ "primary" "secondary" ];
        default = "primary";
      };
      imageFormat = mkOption {
        type = types.enum ["fit" "uimage"];
        default = "uimage";
      };
      tftp = {
        loadAddress = mkOption {
          type = types.ints.unsigned;
          description = ''
            RAM address at which to load data when transferring via
            TFTP. This is not the address of the flash storage,
            nor the kernel load address: it should be set to some part
            of RAM that's not used for anything else and suitable for
            temporary storage.
          '';
        };
        # These names match the uboot environment variables. I reserve
        # the right to change them if I think of better ones.
        ipaddr =  mkOption {
          type = types.str;
          description = ''
            Our IP address to use when creating scripts to
            boot or flash from U-Boot. Not relevant in normal operation
          '';
        };
        serverip = mkOption {
          type = types.str;
          description = ''
            IP address of the TFTP server.  Not relevant in normal operation
          '';
        };
      };
    };
  };
  config = {
    defaultProfile.packages = with pkgs;
      [ s6 s6-init-bin execline s6-linux-init s6-rc ];

    boot.commandLine = [
      "panic=10 oops=panic init=/bin/init loglevel=8"
      "root=${config.hardware.rootDevice}"
      "rootfstype=${config.rootfsType}"
      "fw_devlink=off"
    ] ++ lib.optional (config.rootOptions != null) "rootflags=${config.rootOptions}";

    system.callService = path : parameters :
      let
        typeChecked = caller: type: value:
          let
            inherit (lib) types mergeDefinitions;
            defs = [{ file = caller; inherit value; }];
            type' = types.submodule { options = type; };
          in (mergeDefinitions [] type' defs).mergedValue;
        cp = lib.callPackageWith(pkgs // { svc = config.system.service; });
        pkg = cp path {};
        checkTypes = t : p : typeChecked (builtins.toString path) t p;
      in {
        inherit parameters;
        build = { dependencies ? [], ... } @ args :
          let
            s = pkg (checkTypes parameters
              (builtins.removeAttrs args ["dependencies"]));
          in s.overrideAttrs (o: {
            dependencies = (builtins.map (d: d.name) dependencies) ++ o.dependencies;
            buildInputs = dependencies ++ o.buildInputs;
          });
      };



    users.root = {
      uid = 0; gid= 0; gecos = "Root of all evaluation";
      dir = "/home/root/";
      passwd = lib.mkDefault "";
      shell = "/bin/sh";
    };
    groups = {
      root = {
        gid = 0; usernames = ["root"];
      };
      system = {
        gid = 1; usernames = ["root"];
      };
    };

    filesystem = dir {
      dev =
        let node = type: major: minor: mode : { inherit type major minor mode; };
        in dir {
          null =    node "c" "1" "3" "0666";
          zero =    node "c" "1" "5" "0666";
          tty =     node "c" "5" "0" "0666";
          console = node "c" "5" "1" "0600";
          pts =     dir {};
        };
      etc = let
        profile = symlink
          (pkgs.writeScript ".profile" ''
           PATH=${lib.makeBinPath config.defaultProfile.packages}:/bin
            export PATH
            '');
      in dir {
        inherit profile;
        ashrc = profile;
      };

      proc = dir {};
      run = dir {};
      sys = dir {};
      tmp = dir {};
    };
  };
}
