{
  smoke = import ./smoke/test.nix;
  pseudofiles = import ./pseudofiles/test.nix;
  wlan = import ./wlan/test.nix;
  pppoe = import ./pppoe/test.nix;
}
