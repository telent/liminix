{
  smoke = import ./tests/smoke/test.nix;
  pseudofiles = import ./tests/pseudofiles/test.nix;
  pppoe = import ./tests/pppoe/test.nix;
}
