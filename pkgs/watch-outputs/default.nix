{
  fetchurl,
  writeFennel,
  fennel,
  runCommand,
  lua,
  anoia,
  linotify,
  lualinux,
  stdenv,
}:
let
  name = "watch-outputs";
in
stdenv.mkDerivation {
  inherit name;
  src = ./.;

  buildInputs = [ lua ];
  #  doCheck = true;

  buildPhase = ''
    cp -p ${
      writeFennel name {
        packages = [
          anoia
          lualinux
          linotify
          fennel
        ];
        mainFunction = "run";
      } ./watch-outputs.fnl
    } ${name}
  '';
  #  checkPhase = "make check";
  installPhase = ''
    install -D ${name} $out/bin/${name}
  '';
}
