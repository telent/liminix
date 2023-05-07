{
  liminix
, nixpkgs
}:
let lmx = (import liminix {
      device = import "${liminix}/devices/qemu/";
      liminix-config = ./configuration.nix;
    });
    rogue = lmx.pkgs.rogue;
    img = lmx.outputs.vmroot;
    pkgs = import <nixpkgs> { overlays = [(import ../../overlay.nix)]; };
    inherit (pkgs.pkgsBuildBuild) mips-vm;
in pkgs.runCommand "check" {
  nativeBuildInputs = with pkgs; [
    expect
    mips-vm
    socat
    min-copy-closure
    rogue
  ] ;
} ''
. ${../test-helpers.sh}

mkdir vm
LAN=user,hostfwd=tcp::2022-:22 mips-vm --background ./vm ${img}/vmlinux ${img}/rootfs
expect ${./wait-until-ready.expect}
export SSH_COMMAND="ssh -o StrictHostKeyChecking=no -p 2022 -i ${./id}"
$SSH_COMMAND root@localhost echo ready
IN_NIX_BUILD=true min-copy-closure root@localhost ${rogue}
$SSH_COMMAND root@localhost ls -l ${rogue} >$out
''
