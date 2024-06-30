{
  buildGoModule,
  fetchFromGitHub,
  ppp,
}:

buildGoModule rec {
  pname = "go-l2tp";
  version = "0";

  src = fetchFromGitHub {
    repo = "go-l2tp";
    owner = "katalix";
    rev = "570d763";
    hash = "sha256-R8ImKPkPBC+FvzKOBEZ3VxQ12dEjtfRa7AH94xMsAGA=";
  };

  patchPhase = ''
    sed -i.bak -e 's:/usr/sbin/pppd:${ppp}/bin/pppd:' cmd/kl2tpd/pppd.go
    sed -i.bak -e 's:/usr/sbin/kl2tpd:${placeholder "out"}/bin/kl2tpd:' cmd/kpppoed/l2tpd_kl2tpd.go
    grep bin/kl2tp cmd/kpppoed/l2tpd_kl2tpd.go
  '';

  doCheck = false;
  vendorHash = "sha256-hOkhJhToN/VJwjQmnQJSPGz26/YDR2Ch+1yeW51OF+U=";
}
