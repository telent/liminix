{
  ext4 = import ./ext4/test.nix;
  fennel = import ./fennel/test.nix;
  inout = import ./inout/test.nix;
  jffs2 = import ./jffs2/test.nix;
  min-copy-closure = import ./min-copy-closure/test.nix;
  pppoe = import ./pppoe/test.nix;
  pseudofiles = import ./pseudofiles/test.nix;
  smoke = import ./smoke/test.nix;
  tftpboot = import ./tftpboot/test.nix;
  updown = import ./updown/test.nix;
  wlan = import ./wlan/test.nix;
}
