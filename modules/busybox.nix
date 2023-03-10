{ lib, pkgs, config, ...}:
let
  inherit (lib) mkOption mkEnableOption types mapAttrsToList;
  inherit (pkgs.pseudofile) dir symlink;
  inherit (lib.strings) toUpper;

  attrs = { options, applets } :
    let
      extraOptions = builtins.concatStringsSep "\n"
        (mapAttrsToList (n: v: "CONFIG_${toUpper n} ${toString v}") options);
      appletOptions = builtins.concatStringsSep "\n"
        (map (n: "CONFIG_${toUpper n} y") applets);
    in {
      enableMinimal = true;
      extraConfig = ''
        ${extraOptions}
        ${appletOptions}
      '';
    };
  cfg = config.programs.busybox;
  busybox = pkgs.busybox.override (attrs { inherit (cfg) applets options; });
  makeLinks = lib.attrsets.genAttrs
    cfg.applets
    (a: symlink "${busybox}/bin/busybox");
  minimalApplets = [
    # this is probably less minimal than it could be
    "arch" "ash" "base64" "basename" "bc" "brctl" "bunzip2" "bzcat"
    "bzip2" "cal" "cat" "chattr" "chgrp" "chmod" "chown" "chpst"
    "chroot" "clear" "cmp" "comm" "cp" "cpio" "cut" "date" "dd" "df"
    "dirname" "dmesg" "du" "echo" "egrep" "env" "expand" "expr"
    "false" "fdisk" "fgrep" "find" "free" "fuser" "grep" "gunzip"
    "gzip" "head" "hexdump" "hostname" "hwclock" "ifconfig" "ip"
    "ipaddr" "iplink" "ipneigh" "iproute" "iprule" "kill" "killall"
    "killall5" "less" "ln" "ls" "lsattr" "lsof" "md5sum" "mkdir"
    "mknod" "mktemp" "mount" "mv" "nc" "netstat" "nohup" "od" "pgrep"
    "pidof" "ping" "ping6" "pkill" "pmap" "printenv" "printf" "ps"
    "pwd" "readlink" "realpath" "reset" "rm" "rmdir" "route" "sed"
    "seq" "setsid" "sha1sum" "sha256sum" "sha512sum" "sleep" "sort"
    "stat" "strings" "stty" "su" "sum" "swapoff" "swapon" "sync"
    "tail" "tee" "test" "time" "touch" "tr" "traceroute" "traceroute6"
    "true" "truncate" "tty" "udhcpc" "udhcpc6" "umount" "uname"
    "unexpand" "uniq" "unlink" "unlzma" "unxz" "unzip" "uptime"
    "watch" "wc" "whoami" "xargs" "xxd" "xz" "xzcat" "yes" "zcat"
  ];
in {
  options = {
    programs.busybox = {
      applets =  mkOption {
        type = types.listOf types.str;
        default = [];
        example = ["sh" "getty" "login"];
      };
      options = mkOption {
        # mostly the values are y n or m, but sometimes
        # other strings are also used
        type = types.attrsOf types.nonEmptyStr;
        default =  { };
      };
    };
  };
  config = {
    programs.busybox = {
      applets = minimalApplets;
      options = {
        ASH_ECHO = "y";
        # ASH_OPTIMIZE_FOR_SIZE = "y";
        BASH_IS_NONE = "y";
        SH_IS_ASH = "y";
        ASH_BASH_COMPAT = "y";
        FEATURE_EDITING = "y"; # readline-ish command editing
        FEATURE_EDITING_HISTORY = "128";
        FEATURE_EDITING_MAX_LEN = "1024";
        FEATURE_TAB_COMPLETION = "y";
        FEATURE_EDITING_WINCH = "y";
      };
    };
    filesystem = dir {
      bin = dir ({
        busybox = symlink "${busybox}/bin/busybox";
        sh = symlink "${busybox}/bin/busybox";
      } // makeLinks);
    };
  };
}
