{
  lib,
  liminix,
  output-template,
  ppp,
  pppoe,
  serviceFns,
  svc,
  writeAshScript,
  callPackage,
}:
{
  interface,
  ppp-options,
  lcpEcho,
  username,
  password,
  debug,
}:
let
  name = "${interface.name}.pppoe";
  common = callPackage ./common.nix { inherit svc; };

  timeoutOpt =
    if lcpEcho.interval != null then "-T ${builtins.toString (4 * lcpEcho.interval)}" else "";
in
common {
  inherit
    name
    debug
    username
    password
    lcpEcho
    ppp-options
    ;
  command = ''
    exec ${ppp}/bin/pppd pty "${pppoe}/bin/pppoe ${timeoutOpt}  -I $(output ${interface} ifname)" file /run/${name}/ppp-options
  '';
  dependencies = [ interface ];
}
