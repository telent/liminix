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
    rev = "6a87eaf434cb89d4eba0b811a4b5d158fd9c519f";
    hash = "sha256-3pQKMV5cOl6/wmoh9gs6TTiBco/dhp1VzIsVknYk2tw=";
  };

  nativeBuildInputs = [
    cmake
    zlib
    openssl
  ];
}
