{
  fetchurl,
  runCommand,
  lua,
}:
let
  src = fetchurl {
    url = "https://raw.githubusercontent.com/rxi/json.lua/11077824d7cfcd28a4b2f152518036b295e7e4ce/json.lua";
    hash = "sha256-DqzNpX+rwDMHNt4l9Fz1iYIaQrXg/gLk4xJffcC/K34=";
  };
in runCommand "json" {} ''
  mkdir -p $out/share/lua/${lua.luaversion}/
  cp ${src}  $out/share/lua/${lua.luaversion}/json.lua
''
