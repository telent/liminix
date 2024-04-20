{ lua, lib, fetchFromGitHub }:
let pname = "minisock";
in lua.pkgs.buildLuaPackage {
  inherit pname;
  version = "0.1";              # :shrug:

  src = fetchFromGitHub {
    repo = "minisock";
    owner = "philanc";
    rev = "a20db2aaa871653c61045019633279167cf1b458";
    hash = "sha256-zB9KSt0WEGCSYTLA6W9QrsVRFEZYaoBBeXx9VEXmsGY=";
  };

  makeFlags = [ "LUADIR=."  "minisock.so" ];

  installPhase = ''
    mkdir -p "$out/lib/lua/${lua.luaversion}"
    cp ${pname}.so "$out/lib/lua/${lua.luaversion}/"
  '';

}
