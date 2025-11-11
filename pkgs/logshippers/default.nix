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
  name = "logshippers";
  luafy =
    name: source:
    writeFennel name {
      packages = [
        anoia
        lualinux
        fennel
      ];
      macros = [ anoia.dev ];
      mainFunction = "run";
    } source;
  incz = luafy name ./incz.fnl;
  victorialogsend = luafy name ./victorialogsend.fnl;
in
stdenv.mkDerivation {
  inherit name;
  src = ./.;

  buildInputs = [ lua ];
  nativeBuildInputs = [ fennelrepl ];

  buildPhase = ''
    fennelrepl --test ./incz.fnl
    fennelrepl --test ./victorialogsend.fnl
    cp -p ${incz} incz
    cp -p ${victorialogsend} victorialogsend
  '';

  installPhase = ''
    install -D incz $out/bin/incz
    install -D victorialogsend $out/bin/victorialogsend
  '';
}
