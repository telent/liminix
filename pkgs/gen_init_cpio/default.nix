{
  stdenv
, fetchurl
}:
stdenv.mkDerivation rec {
  name = "gen_init_cpio";
  src = fetchurl {
    url = "https://raw.githubusercontent.com/torvalds/linux/462cd7724e2341472c9f9670ac88e250788d4c82/usr/gen_init_cpio.c";
    hash = "sha256-gwKSJGiCS4v98EArNryr/sdYAfDqnGsZ1erfGMNVjpw=";
  };
  unpackPhase = "cp ${src} ./gen_init_cpio.c";
  buildPhase = "gcc -o gen_init_cpio gen_init_cpio.c";
  installPhase = ''
    mkdir -p $out/bin
    cp gen_init_cpio $out/bin
  '';
}
