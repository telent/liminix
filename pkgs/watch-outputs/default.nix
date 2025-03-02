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
    fennelrepl --test ./watch-outputs.fnl
    cp -p ${
      writeFennel name {
        packages = [
          anoia
          lualinux
          linotify
          fennel
        ];
        macros = [ anoia.dev ];
        mainFunction = "run";
      } ./watch-outputs.fnl
    } ${name}
  '';

  installPhase = ''
    install -D ${name} $out/bin/${name}
  '';
}
