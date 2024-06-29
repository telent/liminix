{ stdenv
, cmake
, fetchFromGitHub
, ...} :
# let switchDotH = buildPackages.fetchurl {
#   url = "https://git.openwrt.org/?p=openwrt/openwrt.git;a=blob_plain;f=target/linux/generic/files/include/uapi/linux/switch.h;hb=99a188828713d6ff9c541590b08d4e63ef52f6d7";
#   sha256 = "15kmhhcpd84y4f45rf8zai98c61jyvkc37p90pcxirna01x33wi8";
#   name="switch.h";
# };
stdenv.mkDerivation {
  src = fetchFromGitHub {
    owner = "openwrt";
    repo = "odhcp6c";
    rev = "bcd283632ac13391aac3ebdd074d1fd832d76fa3";
    hash = "sha256-jqxr+N1PffWYmF0F6hJKxRLMN5Ht5WpehK1K2HjL+do=";
  };
  name = "odhcp6c";
  nativeBuildInputs = [ cmake ];
}
