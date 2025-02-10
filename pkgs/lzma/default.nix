{ stdenv, fetchurl }:
stdenv.mkDerivation {
  pname = "lzma";
  version = "4.32.7";
  configureFlags = [
    "--enable-static"
    "--disable-shared"
  ];
  src = fetchurl {
    url = "https://tukaani.org/lzma/lzma-4.32.7.tar.gz";
    sha256 = "0b03bdvm388kwlcz97aflpr3ir1zpa3m0bq3s6cd3pp5a667lcwz";
  };
}
