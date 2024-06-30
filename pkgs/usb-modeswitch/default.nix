# usb modeswitch without udev, tcl, coreutils, bash dependencies
{
  stdenv,
  lib,
  fetchurl,
  pkg-config,
  libusb1,
}:
let
  pname = "usb-modeswitch";
  version = "2.6.0";
in stdenv.mkDerivation {
  inherit pname version;

  src = fetchurl {
    url = "http://www.draisberghof.de/usb_modeswitch/${pname}-${version}.tar.bz2";
    sha256 = "18wbbxc5cfsmikba0msdvd5qlaga27b32nhrzicyd9mdddp265f2";
  };

  preBuild = ''
    makeFlagsArray+=(LIBS="$($PKG_CONFIG --libs --cflags libusb-1.0)")
  '';
  makeFlags = [
    "PREFIX=$(out)"
    "usb_modeswitch"
  ];

  buildInputs = [ libusb1 ];
  nativeBuildInputs = [ pkg-config ];

  installPhase = ''
    mkdir -p $out/bin
    cp usb_modeswitch $out/bin
  '';

  meta = {
    license = lib.licenses.gpl2;
    maintainers = [ ];
  };
}
