{
  lua5_3
, stdenv
, fennel
, fetchFromGitHub
, makeWrapper
} :
let
  tufty-lua = lua.pkgs.buildLuaPackage {
    pname = "tufty";
    version = "1";
    src = fetchFromGitHub {
      owner = "telent";
      repo = "tufty";
      sha256 = "sha256-m5UEfcCNdG0Ku380cPhu1inNQmSfQJ5NcRIxLohUOh8=";
      rev = "75c6d38713a82f4197f91dcb182a2e34f255bf7c";
    };
    buildPhase = ":";
    installPhase = ''
        mkdir -p "$out/share/lua/${lua5_3.luaversion}"
        cp src/*.lua "$out/share/lua/${lua5_3.luaversion}/"
      '';
  };
  lua = lua5_3.withPackages (ps: with ps; [
    tufty-lua luasocket luaposix
  ]);
  fennel_ = (fennel.override { inherit lua; });
in stdenv.mkDerivation {
  pname = "tufted";
  version = "1";
  phases =  [ "unpackPhase" "installPhase" ];
  buildInputs = [ lua fennel_ ];
  nativeBuildInputs = [ makeWrapper ];
  src = ./.;
  installPhase = ''
    mkdir -p $out/lib
    cp tufted.fnl $out/lib
    makeWrapper ${fennel_}/bin/fennel \
      $out/bin/tufted \
      --add-flags "--add-fennel-path $out/lib/?.fnl" \
      --add-flags "--add-package-path $out/lib/?.lua" \
      --add-flags "$out/lib/tufted.fnl"
  '';
}
