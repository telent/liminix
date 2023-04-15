{
  stdenv
, fetchzip
, gdb
 }:
let kernel = fetchzip {
      name = "linux";
      url = "https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.15.71.tar.gz";
      hash = "sha256-pq6QNa0PJVeheaZkuvAPD0rLuEeKrViKk65dz+y4kqo=";
    };
in
stdenv.mkDerivation {
  name = "preinit";
  src = ./.;

  #  NIX_DEBUG=2;
  hardeningDisable = [ "all" ];
  CFLAGS = "-Os  -nostartfiles -nostdlib  -fno-stack-protector -fpic -fPIC  -I ./ -I ${kernel}/tools/include/nolibc";

  postBuild = ''
    $STRIP  --remove-section=.note --remove-section=.comment preinit
  '';

  makeFlags = ["preinit"];
  stripAllList = ["bin"];
  installPhase = ''
    mkdir -p $out/bin
    cp preinit $out/bin
  '';
}
