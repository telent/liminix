{
  fetchurl,
  writeFennel,
  fennel,
  fennelrepl,
  runCommand,
  lua,
  anoia,
  lualinux,
  fetch-freebsd,
  openssl,
  luaossl',
  stdenv,
}:
let
  name = "certifix-client";
in
stdenv.mkDerivation {
  inherit name;
  src = ./.;

  buildInputs = [
    fetch-freebsd
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
          fennel
          anoia
          lualinux
          luaossl'
        ];
        mainFunction = "run";
      } ./${name}.fnl
    } $out/bin/${name}
  '';
}
