{
  cmake,
  stdenv,
  openssl,
  fetchFromGitHub
}: stdenv.mkDerivation {
  pname = "fetch-freebsd";
  version = "v12.0.11";
  src = fetchFromGitHub {
    owner= "jrmarino";
    repo = "fetch-freebsd";
    rev =  "v12.0.11";
    hash = "sha256-nLNqjQFV9x2NntBdUlabxjS9q+er28zi8uXjWvCK2Ps=";
  };
  cmakeFlags = [
    "-DFETCH_PROGRAM=OFF"
    "-DFETCH_LIBRARY=ON"
    "-DUSE_SYSTEM_SSL=ON"
  ];
  nativeBuildInputs = [ cmake ];
  buildInputs = [ openssl ];
  postInstall = ''
    rm -r $out/lib/lib*.a
  '';
}
