{
  fetchurl,
  writeFennel,
  fennel,
  fennelrepl,
  runCommand,
  lua,
  anoia,
  lualinux,
  stdenv,
}:
let
  name = "incz";
in
stdenv.mkDerivation {
  inherit name;
  src = ./.;

  buildInputs = [ lua ];
  nativeBuildInputs = [ fennelrepl ];

  buildPhase = ''
    fennelrepl --test ./incz.fnl
    cp -p ${
      writeFennel name {
        packages = [
          anoia
          lualinux
          fennel
        ];
        macros = [
          anoia.dev
        ];
        mainFunction = "run";
      } ./incz.fnl
    } ${name}
  '';

  installPhase = ''
    install -D ${name} $out/bin/${name}
  '';
}
