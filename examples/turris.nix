{
  config,
  pkgs,
  lim,
  ...
}:
let
  svc = config.system.service;

in
rec {
  imports = [
    ../modules/network
    ../modules/ssh
    ../modules/vlan
    ../modules/wlan.nix
    ../modules/hostapd
    ../modules/bridge

    ../modules/ext4fs.nix
    ../modules/tftpboot.nix
  ];

  rootfsType = "ext4";

  boot.tftp = {
    # IP addresses to use in the boot monitor when flashing/ booting
    # over TFTP. If you are flashing using the stock firmware's Web UI
    # then these dummy values are fine
    ipaddr = "10.0.0.8"; # my address
    serverip = "10.0.0.1"; # build machine or other tftp server
    loadAddress = lim.parseInt "0x40000800";
  };

  hostname = "omnia";

  services.hostap =
    let
      secrets = {
        ssid = "not-the-internet";
        channel = 4;
        wpa_passphrase = "diamond dogs";
      };
    in
    svc.hostapd.build {
      interface = config.hardware.networkInterfaces.wlan;
      params = {
        country_code = "GB";
        hw_mode = "g";
        wmm_enabled = 1;
        ieee80211n = 1;
        inherit (secrets) ssid channel wpa_passphrase;
        auth_algs = 1; # 1=wpa2, 2=wep, 3=both
        wpa = 2; # 1=wpa, 2=wpa2, 3=both
        wpa_key_mgmt = "WPA-PSK";
        wpa_pairwise = "TKIP CCMP"; # auth for wpa (may not need this?)
        rsn_pairwise = "CCMP"; # auth for wpa2
      };
    };

  services.hostap5 =
    let
      secrets = {
        ssid = "not-the-internet";
        channel = 36;
        wpa_passphrase = "diamond dogs";
      };
    in
    svc.hostapd.build {
      interface = config.hardware.networkInterfaces.wlan5;
      params = {
        country_code = "GB";
        hw_mode = "a";

        ht_capab = "[HT40+]";
        vht_oper_chwidth = 1;
        vht_oper_centr_freq_seg0_idx = secrets.channel + 6;
        ieee80211ac = 1;

        wmm_enabled = 1;
        inherit (secrets) ssid channel wpa_passphrase;
        auth_algs = 1; # 1=wpa2, 2=wep, 3=both
        wpa = 2; # 1=wpa, 2=wpa2, 3=both
        wpa_key_mgmt = "WPA-PSK";
        wpa_pairwise = "TKIP CCMP"; # auth for wpa (may not need this?)
        rsn_pairwise = "CCMP"; # auth for wpa2
      };
    };

  services.int = svc.bridge.primary.build {
    ifname = "int";
  };

  services.dhcpc = svc.network.dhcp.client.build {
    interface = services.int;
    dependencies = [ config.services.hostname ];
  };

  services.bridge = svc.bridge.members.build {
    primary = services.int;
    members = with config.hardware.networkInterfaces; [
      lan
      wlan
    ];
  };

  services.sshd = svc.ssh.build { };

  users.root = {
    # the password is "secret". Use mkpasswd -m sha512crypt to
    # create this hashed password string
    passwd = "$6$y7WZ5hM6l5nriLmo$5AJlmzQZ6WA.7uBC7S8L4o19ESR28Dg25v64/vDvvCN01Ms9QoHeGByj8lGlJ4/b.dbwR9Hq2KXurSnLigt1W1";
  };

  defaultProfile.packages = with pkgs; [
    figlet
    pciutils
  ];
}
