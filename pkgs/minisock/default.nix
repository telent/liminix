{ lua, lib, fetchFromGitHub }:
let
  pname = "minisock";
  src = fetchFromGitHub {
    repo = "minisock";
    owner = "telent";
    rev = "f31926e8aac6922923d4e83ed3e85b727172e9c5";
    hash = "sha256-/RlhnRrIrXa/86mX20RMLtzmGdoeA7zVc8uBoFyexnY=";
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
