{ lua, lib, fetchpatch, fetchFromGitHub, libmnl }:
let pname = "netlink";
in lua.pkgs.buildLuaPackage {
  inherit pname;
  version = "0.1.1-1";

  buildInputs = [ libmnl ];

  src = fetchFromGitHub {
    repo = "lua-netlink";
    owner = "chris2511";
    rev = "ff8d2012ea42291c87150ba47d4cd89860f7872e";
    hash = "sha256-tnvFKXxLX+/Q4nJcRDrUfK7bAHBWEANFTBR1PjbQsmQ=";
  };

  buildPhase = "$CC -shared -l mnl -l lua -o netlink.so src/*.c";

  installPhase = ''
    mkdir -p "$out/lib/lua/${lua.luaversion}"
    cp  netlink.so "$out/lib/lua/${lua.luaversion}/"
  '';

}
