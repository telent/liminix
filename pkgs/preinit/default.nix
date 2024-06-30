{ stdenv, gdb }:
stdenv.mkDerivation {
  name = "preinit";
  src = ./.;

  #  NIX_DEBUG=2;
  hardeningDisable = [ "all" ];

  postBuild = ''
    $STRIP  --remove-section=.note --remove-section=.comment preinit
    ls -l preinit
  '';

  makeFlags = [ "preinit" ];
  stripAllList = [ "bin" ];
  installPhase = ''
    mkdir -p $out/bin
    cp preinit $out/bin
  '';
}
