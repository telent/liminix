{
  lua,
  runCommand,
}:
let
  fennel = lua.pkgs.fennel;
in
runCommand "build-fennelc"
  {
    nativeBuildInputs = [ fennel ];
  }
  ''
    LUAPATH=$(ls -d ${fennel}/share/lua/*)
    mkdir -p $out/bin
    (
    exec > $out/bin/fennelc
    echo '#! ${lua}/bin/lua'
    echo "package.path = \"''${LUAPATH}/?.lua;''${LLPATH}/?.lua;\" .. package.path"
    fennel  --compile ${./fennelc.fnl}
    )
    chmod +x $out/bin/fennelc
  ''
