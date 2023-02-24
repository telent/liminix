{ lua, lib, fetchpatch, fetchFromGitHub, libmnl }:
let pname = "netlink";
in lua.pkgs.buildLuaPackage {
  inherit pname;
  version = "0.1.1-1";

  buildInputs = [ libmnl ];

  src = fetchFromGitHub {
    repo = "lua-netlink";
    owner = "chris2511";
    rev = "v0.1.1";
    hash = "sha256:1833naskl4p7rz5kk0byfgngvw1mvf6cnz64sr3ny7i202wv7s52";
  };

  buildPhase = "$CC -shared -l mnl -l lua -o netlink.so src/*.c";

  installPhase = ''
    mkdir -p "$out/lib/lua/${lua.luaversion}"
    cp  netlink.so "$out/lib/lua/${lua.luaversion}/"
  '';

}
