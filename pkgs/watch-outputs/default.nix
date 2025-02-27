{
  fetchurl,
  writeFennel,
  fennel,
  fennelrepl,
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
  nativeBuildInputs = [ fennelrepl ] ;

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
    make check
  '';

  installPhase = ''
    install -D ${name} $out/bin/${name}
  '';
}
