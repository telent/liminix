{ lua, fetchFromGitHub }:
let pname = "linotify";
in lua.pkgs.buildLuaPackage {
  inherit pname;
  version = "0.5";

  src = fetchFromGitHub {
    repo = "linotify";
    owner = "hoelzro";
    rev = "a56913e9c0922befb65227a00cf69c2e8052de1a";
    hash = "sha256-IlOJbGx1zbOR3vgNMsNTPsarhPANpzl7jsu33LEbIqY=";
  };

  installPhase = ''
    mkdir -p "$out/lib/lua/${lua.luaversion}"
    cp inotify.so "$out/lib/lua/${lua.luaversion}/"
  '';

}
