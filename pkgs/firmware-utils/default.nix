{
  stdenv,
  fetchFromGitHub,
  cmake,
  zlib,
  openssl,
}:

stdenv.mkDerivation {
  pname = "firmware-utils";
  version = "snapshot";

  src = fetchFromGitHub {
    owner = "openwrt";
    repo = "firmware-utils";
    rev = "e87f23849790a7c77b4cd0e8ef0384da188174e5";
    hash = "sha256-285Isf9sRuUt5S56SozgqpnS0+LOfnvpxpnWLwuWYUk=";
  };

  nativeBuildInputs = [
    cmake
    zlib
    openssl
  ];
}
