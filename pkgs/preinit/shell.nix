with import <nixpkgs> { };
mkShell {
  name = "preinit-env";
  src = ./.;
}
