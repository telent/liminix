{
  stdenv,
  fetchFromGitLab,
  makeWrapper,
  btrfs-progs,
  util-linux-small,
  lib,
}:
let
  search_path = lib.makeBinPath [
    btrfs-progs
    util-linux-small
  ];
in
stdenv.mkDerivation {
  pname = "schnapps";
  version = "2.13.0";

  src = fetchFromGitLab {
    domain = "gitlab.nic.cz";
    owner = "turris";
    repo = "schnapps";
    rev = "53ac92c765d670be4b98dba2c948859a9ac7607f";
    hash = "sha256-yVgXK+V2wrcOPLB6X6qm3hyBcWcyzNhfJjFF7YRk5Lc=";
  };

  nativeBuildInputs = [ makeWrapper ];
  buildPhase = ":";
  installPhase = ''
    install -D schnapps.sh $out/bin/schnapps
    wrapProgram $out/bin/schnapps --prefix PATH : "${search_path}"
  '';
}
