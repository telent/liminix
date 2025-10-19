{
  fetchurl,
  writeFennel,
  fennel,
  fennelrepl,
  runCommand,
  lua,
  anoia,
  lualinux,
  openssl,
  stdenv,
}:
let
  name = "certifix-client";
in
stdenv.mkDerivation {
  inherit name;
  src = ./.;

  buildInputs = [
    openssl
    lua
  ];

  buildPhase = "";
  installPhase = ''
    mkdir -p $out/bin
    cp -p ${
      writeFennel name {
        packages = with lua.pkgs; [
          fennel
          anoia
          lualinux
          luaossl
          http
          lpeg
          lpeg_patterns
          basexx
          cqueues
          fifo
          binaryheap
        ];
        mainFunction = "run";
      } ./${name}.fnl
    } $out/bin/${name}
  '';
}
