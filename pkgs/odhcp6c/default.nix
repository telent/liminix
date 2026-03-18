{
  stdenv,
  cmake,
  fetchFromGitHub,
  ...
}:
# let switchDotH = buildPackages.fetchurl {
#   url = "https://git.openwrt.org/?p=openwrt/openwrt.git;a=blob_plain;f=target/linux/generic/files/include/uapi/linux/switch.h;hb=99a188828713d6ff9c541590b08d4e63ef52f6d7";
#   sha256 = "15kmhhcpd84y4f45rf8zai98c61jyvkc37p90pcxirna01x33wi8";
#   name="switch.h";
# };
stdenv.mkDerivation {
  src = fetchFromGitHub {
    owner = "openwrt";
    repo = "odhcp6c";
    # this is the last revision before libubox was made a
    # mandatory dependency
    # https://github.com/openwrt/odhcp6c/pull/109/commits
    rev = "5182e2b696ef21cb2df00e8e399e0af7c1b7bf6d";

    hash = "sha256-i4ApAgeJ9tk8cPKgyaOQG9gdQzPjl3BsDWcZOe/INeM=";
  };
  name = "odhcp6c";
  nativeBuildInputs = [ cmake ];
}
