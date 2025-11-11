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
  name = "output-template";
in
stdenv.mkDerivation {
  inherit name;
  src = ./.;

  buildInputs = [ lua ];
  nativeBuildInputs = [ fennelrepl ];
  buildPhase = ''
    fennelrepl --test ./output-template.fnl
    cp -p ${
      writeFennel name {
        packages = [
          anoia
          lualinux
          linotify
        ];
        macros = [ anoia.dev ];
        mainFunction = "run";
      } ./output-template.fnl
    } ${name}
  '';
  installPhase = ''
    install -D ${name} $out/bin/${name}
  '';
}
