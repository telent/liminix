{ stdenv
, cmake
, zlib
, libyaml
, fetchFromGitHub
} :
stdenv.mkDerivation {
  name = "libubootenv";
  src = fetchFromGitHub {
    owner = "sbabic";
    repo = "libubootenv";
    rev = "3f4d15e36ceb58085b08dd13f3f2788e9299877b"; # v0.3.5
    hash = "sha256-i7gUb1A6FTOBCpympQpndhOG9pCDA4P0iH7ZNBqo+PA=";
  };
  buildInputs = [ zlib libyaml ];
  nativeBuildInputs = [ cmake ];
}
