{
  fetchFromGitHub
, stdenv
, autoreconfHook
, substituteAll
# , openssl
}: stdenv.mkDerivation {
  pname  = "ppp";
  version = "2.5.0";
  nativeBuildInputs = [ autoreconfHook ];
#  buildInputs= [ openssl ];

  src = fetchFromGitHub {
    repo = "ppp";
    owner = "ppp-project";
    rev = "ppp-2.5.0";
    hash = "sha256-J7udiLiJiJ1PzNxD+XYAUPXZ+ABGXt2U3hSFUWJXe94=";
  };

  configureFlags = [
    "--disable-eaptls"
    "--disable-peap"
    "--disable-openssl-engine"
    "--without-openssl"
  ];

  postPatch = ''
    sed -i.bak pppd/crypto_ms.c -e '/#include <openssl\/evp.h>/d'
    sed -i.bak pppd/ppp-sha1.c -e 's/u_int32_t/uint32_t/g' -e '1i#include <stdint.h>'
  '';

  outputs = [
    "bin"
    "out"
    "man"
    "dev"
  ];


}
