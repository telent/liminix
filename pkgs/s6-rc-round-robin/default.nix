{
  lualinux,
  writeFennel,
  anoia,
  linotify,
  fennel,
  stdenv,
  s6-rc-up-tree,
}:
stdenv.mkDerivation {
  name = "s6-rc-round-robin";
  src = ./.;
  propagatedBuildInputs = [ s6-rc-up-tree ];
  installPhase = ''
    mkdir -p $out/bin
    cp -p ${
      writeFennel "s6-rc-round-robin" {
        packages = [
          fennel
          anoia
          linotify
          lualinux
          s6-rc-up-tree
        ];
        mainFunction = "run";
      } ./robin.fnl
    } $out/bin/s6-rc-round-robin
  '';
}
