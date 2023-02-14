{
  buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "go-l2tp";
  version = "0";

  src = fetchFromGitHub {
    repo = "go-l2tp";
    owner = "katalix";
    rev = "570d763";
    hash= "sha256-R8ImKPkPBC+FvzKOBEZ3VxQ12dEjtfRa7AH94xMsAGA=";
  };
  doCheck = false;
  vendorHash = "sha256-hOkhJhToN/VJwjQmnQJSPGz26/YDR2Ch+1yeW51OF+U=";

}
