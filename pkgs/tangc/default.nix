{
  fetchurl,
  writeFennel,
  fennel,
  fennelrepl,
  runCommand,
  jose,
  lua,
  anoia,
  lualinux,
  fetch-freebsd,
  openssl,
  rxi-json,
  makeWrapper,
  stdenv
}:
let name = "tangc";
in stdenv.mkDerivation {
  inherit name;
  src = ./.;

  buildInputs = [fetch-freebsd rxi-json openssl lua jose];
  nativeBuildInputs = [ makeWrapper ];

  buildPhase = "";
  installPhase = ''
    mkdir -p $out/bin
    cp -p ${writeFennel name {
      packages = [
        fetch-freebsd
        rxi-json
        fennel
        anoia
        lualinux
        jose
      ] ;
      mainFunction = "run";
    } ./tangc.fnl } $out/bin/${name}
    wrapProgram $out/bin/${name} --set JOSE_BIN ${jose}/bin/jose
  '';
}
