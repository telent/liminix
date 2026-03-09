{
  fetchFromGitHub,
  gcc13Stdenv,
  autoreconfHook,
  substituteAll,
}:
let stdenv = gcc13Stdenv; in
stdenv.mkDerivation {
  pname = "ppp";
  version = "2.5.2";
  nativeBuildInputs = [ autoreconfHook ];

  src = fetchFromGitHub {
    repo = "ppp";
    owner = "ppp-project";
    rev = "v2.5.2";
    hash = "sha256-NV8U0F8IhHXn0YuVbfFr992ATQZaXA16bb5hBIwm9Gs=";
  };

  configureFlags = [
    "--disable-eaptls"
    "--disable-peap"
    "--disable-openssl-engine"
    "--without-openssl"
    "--with-runtime-dir=/run/"
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
