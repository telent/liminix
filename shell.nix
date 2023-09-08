let
  nixpkgs = <nixpkgs>;
  liminix = (import ./default.nix {
    device = (import ./devices/qemu);
    liminix-config = ./vanilla-configuration.nix;
    inherit nixpkgs;
  });
  here = builtins.toString ./.;
in liminix.buildEnv.overrideAttrs (o: {
  nativeBuildInputs = o.nativeBuildInputs ++ [ (import nixpkgs {}).sphinx ] ;
  shellHook = ''
    publish(){  make -C doc html && rsync -azv doc/_build/html/ myhtic.telent.net:/var/www/blogs/www.liminix.org/_site/doc; }
  '';
  FENNEL_PATH = "${here}/pkgs/?/init.fnl;${here}/pkgs/?.fnl";
})
