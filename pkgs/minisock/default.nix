{ lua, lib, fetchFromGitHub }:
let
  pname = "minisock";
  src = fetchFromGitHub {
    repo = "minisock";
    owner = "telent";
    rev = "46e0470ff88c68f3a873dedbcf1dc351f4916b1a";
    hash = "sha256-uTV5gpfEMvHMBgdu41Gy2uizc3K9bXtO5BiCY70cYUs=";
  };
in lua.pkgs.buildLuaPackage {
  inherit pname;
  version = "0.1";              # :shrug:

  inherit src;
  makeFlags = [ "LUADIR=."  "minisock.so" ];

  installPhase = ''
    mkdir -p "$out/lib/lua/${lua.luaversion}"
    cp ${pname}.so "$out/lib/lua/${lua.luaversion}/"
  '';

}
