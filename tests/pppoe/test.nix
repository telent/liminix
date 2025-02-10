let
  img =
    (import <liminix> {
      device = import <liminix/devices/qemu>;
      liminix-config = ./configuration.nix;
    }).outputs.default;
  pkgs = import <nixpkgs> { overlays = [ (import ../../overlay.nix) ]; };
  inherit (pkgs.pkgsBuildBuild) routeros;
in
pkgs.runCommand "check"
  {
    nativeBuildInputs = with pkgs; [
      python3Packages.scapy
      expect
      jq
      socat
      routeros.routeros
    ];
  }
  ''
    serverstatedir=$(mktemp -d -t routeros-XXXXXX)
    # python scapy drags in matplotlib which doesn't enjoy running in
    # a sandbox with no $HOME, hence this environment variable
    export MPLCONFIGDIR=$(mktemp -d -t routeros-XXXXXX)
    export XDG_CONFIG_HOME=/tmp
    export XDG_CACHE_HOME=/tmp

    . ${../test-helpers.sh}

    routeros $serverstatedir
    mkdir vm
    ${img}/run.sh --background ./vm
    expect ${./getaddress.expect}

    set -o pipefail
    response=$(python ${./test-dhcp-service.py})
    echo "$response" | jq -e 'select((.router ==  "192.168.19.1") and (.server_id=="192.168.19.1"))'
    echo $response > $out
  ''
