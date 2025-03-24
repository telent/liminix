{ lua, fetchFromGitHub }:
let
  pname = "lualinux";
  src = fetchFromGitHub {
    repo = "lualinux";
    owner = "philanc";
    rev = "1d4c962aad9cbe01c05df741b91e8b39c356362c";
    hash = "sha256-+Ys4sERG+TI8nRzG38UP+KqbH0efspaX0j4IHCt56RI=";
  };
in
lua.pkgs.buildLuaPackage {
  inherit pname;
  version = "0.1"; # :shrug:

  inherit src;

  patches = [
    ./0001-realpath.patch
  ];

  postPatch = ''
    sed -i -e '/strip/d' Makefile
  '';
  makeFlags = [
    "LUADIR=."
    "CC:=$(CC)"
    "STRIP=true"
    "lualinux.so"
  ];

  installPhase = ''
    mkdir -p "$out/lib/lua/${lua.luaversion}"
    cp ${pname}.so "$out/lib/lua/${lua.luaversion}/"
  '';
}
