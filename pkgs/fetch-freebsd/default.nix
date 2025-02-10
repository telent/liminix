{
  cmake,
  stdenv,
  openssl,
  lua,
  fetchFromGitHub,
}:
stdenv.mkDerivation {
  pname = "fetch-freebsd";
  version = "v12.0.11";
  src = fetchFromGitHub {
    owner = "jrmarino";
    repo = "fetch-freebsd";
    rev = "v12.0.11";
    hash = "sha256-nLNqjQFV9x2NntBdUlabxjS9q+er28zi8uXjWvCK2Ps=";
  };
  cmakeFlags = [
    "-DFETCH_PROGRAM=OFF"
    "-DFETCH_LIBRARY=ON"
    "-DUSE_SYSTEM_SSL=ON"
  ];
  postBuild = ''
    $CC -shared -o fetch-lua.so ${./lua-glue.c} -I$src -Llibrary -lssl -lfetch -llua
  '';
  nativeBuildInputs = [ cmake ];
  buildInputs = [
    lua
    openssl
  ];
  postInstall = ''
    rm -r $out/lib/lib*.a
    mkdir -p $out/lib/lua/${lua.luaversion}
    install fetch-lua.so  $out/lib/lua/${lua.luaversion}/fetch.so
  '';
}
