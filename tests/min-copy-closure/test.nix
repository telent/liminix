let
  lmx = (
    import <liminix> {
      device = import <liminix/devices/qemu>;
      liminix-config = ./configuration.nix;
    }
  );
  myPkg = lmx.pkgs.rsyncSmall;
  img = lmx.outputs.vmroot;
  pkgs = import <nixpkgs> { overlays = [ (import ../../overlay.nix) ]; };
in
pkgs.runCommand "check"
  {
    nativeBuildInputs = with pkgs; [
      expect
      socat
      min-copy-closure
      myPkg
    ];
  }
  ''
    . ${../test-helpers.sh}

    (
    mkdir vm
    ${img}/run.sh --lan user,hostfwd=tcp::2022-:22  --background ./vm
    expect ${./wait-until-ready.expect}
    echo ready to go
    export SSH_COMMAND="ssh -o StrictHostKeyChecking=no -p 2022 -i ${./id}"
    $SSH_COMMAND root@localhost echo ready
    IN_NIX_BUILD=true min-copy-closure --quiet root@localhost ${myPkg}
    $SSH_COMMAND root@localhost ls -ld ${myPkg}
    IN_NIX_BUILD=true min-copy-closure --root /run root@localhost ${myPkg}
    $SSH_COMMAND root@localhost ls -ld /run/${myPkg}
    ) 2>&1 | tee $out
  ''
