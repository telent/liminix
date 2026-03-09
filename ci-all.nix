let jobs = import ./ci.nix ;
    pkgs = import <nixpkgs> { };
in pkgs.mkShell {
  name = "all tests";
  contents = pkgs.lib.collect pkgs.lib.isDerivation jobs;
}
