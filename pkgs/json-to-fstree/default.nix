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
  fetch-freebsd,
  openssl,
  rxi-json,
  stdenv,
}:
let
  name = "json-to-fstree";
in
stdenv.mkDerivation {
  inherit name;
  src = ./.;

  buildInputs = [
    fetch-freebsd
    rxi-json
    openssl
    lua
  ];

  buildPhase = "";
  installPhase = ''
    mkdir -p $out/bin
    cp -p ${
      writeFennel name {
        packages = [
          fetch-freebsd
          rxi-json
          anoia
          lualinux
          linotify
        ];
        mainFunction = "run";
      } ./${name}.fnl
    } $out/bin/${name}
  '';
}
