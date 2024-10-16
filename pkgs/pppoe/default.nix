{
  lib,
  stdenv,
  fetchFromGitHub,
  ppp,
}:
stdenv.mkDerivation rec {
  pname = "rp-pppoe";
  version = "3.15";

  src = fetchFromGitHub {
    owner = "dfskoll";
    repo = "rp-pppoe";
    rev = "7cfd8c0405d14cf1c8d799d41d8207fd707979c1";
    hash = "sha256-MFdCwNj8c52blxEuXH5ltT2yYDmKMH5MLUgtddZV25E=";
  };

  buildInputs = [ ppp ];

  preConfigure = ''
    cd src
    export PPPD=${ppp}/sbin/pppd
  '';

  postConfigure = ''
    sed -i Makefile -e 's@DESTDIR)/etc/ppp@out)/etc/ppp@'
    sed -i Makefile -e 's@PPPOESERVER_PPPD_OPTIONS=@&$(out)@'
  '';

  installPhase = ''
    mkdir -p $out/bin $out/lib
    cp pppoe pppoe-server $out/bin # ppoe-relay pppoe-sniff?
    test -e rp-pppoe.so && cp rp-pppoe.so $out/lib
    true
  '';
  makeFlags = [ "AR:=$(AR)" ];

  meta = with lib; {
    description = "Roaring Penguin Point-to-Point over Ethernet tool";
    platforms = platforms.linux;
    homepage = "https://www.roaringpenguin.com/products/pppoe";
    license = licenses.gpl2Plus;
  };
}
