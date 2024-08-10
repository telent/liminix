{
  fetchurl,
  writeFennel,
  fennel,
  runCommand,
  lua,
  anoia,
  linotify,
  lualinux,
  stdenv
}:
let name = "output-template";
in stdenv.mkDerivation {
  inherit name;
  src = ./.;

  buildInputs = [lua];
  doCheck = true;

  buildPhase = ''
    cp -p ${writeFennel name {
      packages = [
        anoia
        lualinux
        linotify
      ] ;
      mainFunction = "run";
    } ./output-template.fnl } ${name}
  '';
  checkPhase = "make check";
  installPhase = ''
    install -D ${name} $out/bin/${name}
  '';
}
