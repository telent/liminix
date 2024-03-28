{
  liminix
, nixpkgs
}:
let img = (import liminix {
      device = import "${liminix}/devices/qemu/";
      liminix-config = ./configuration.nix;
    }).outputs.vmroot;
    pkgs = import <nixpkgs> { overlays = [(import ../../overlay.nix)]; };
in pkgs.runCommand "check" {
  nativeBuildInputs = with pkgs; [
    expect
    socat
  ] ;
} ''
mkdir vm
${img}/run.sh --flag -S --background ./vm
expect ${./script.expect} | tee $out
''
