{
  lua,
  fetchFromGitHub,
  libmnl,
}:
let
  pname = "netlink";
in
lua.pkgs.buildLuaPackage {
  inherit pname;
  version = "0.1.1-1";

  buildInputs = [ libmnl ];

  src = fetchFromGitHub {
    repo = "lua-netlink";
    owner = "chris2511";
    rev = "41e5ced77a5d68239988ac71ca9476ad496dc047";
    hash = "sha256-z4EK2sKxTdDShhD8e5Z6IeZyQduwOqbXeXmkMhsOTIU=";
  };

  buildPhase = "$CC -shared -l mnl -l lua -DVERSION=\\\"1.1.0\\\" -o netlink.so src/*.c";

  installPhase = ''
    mkdir -p "$out/lib/lua/${lua.luaversion}"
    cp  netlink.so "$out/lib/lua/${lua.luaversion}/"
  '';

}
