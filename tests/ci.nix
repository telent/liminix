{
  smoke = import ./smoke/test.nix;
  pseudofiles = import ./pseudofiles/test.nix;
  pppoe = import ./pppoe/test.nix;
}
