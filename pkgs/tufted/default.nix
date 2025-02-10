{
  lua5_3,
  stdenv,
  makeWrapper,
}:
let
  lua = lua5_3.withPackages (
    ps: with ps; [
      luasocket
      luaposix
      fennel
    ]
  );
in
stdenv.mkDerivation {
  pname = "tufted";
  version = "1";
  phases = [
    "unpackPhase"
    "installPhase"
  ];
  buildInputs = [
    lua
  ];
  nativeBuildInputs = [ makeWrapper ];
  src = ./.;
  installPhase = ''
    mkdir -p $out/lib
    cp tftp.lua tufted.fnl $out/lib
    makeWrapper ${lua.pkgs.fennel}/bin/fennel \
      $out/bin/tufted \
      --prefix LUA_CPATH \; "${lua}/lib/lua/5.3/?.so" \
      --add-flags "--add-fennel-path $out/lib/?.fnl" \
      --add-flags "--add-package-path $out/lib/?.lua" \
      --add-flags "--add-package-path ${lua}/share/lua/5.3/?.lua\;${lua}/share/lua/5.3/?/init.lua" \
      --add-flags "$out/lib/tufted.fnl"
  '';
}
