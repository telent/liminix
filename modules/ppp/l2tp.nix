{
  lib,
  liminix,
  output-template,
  serviceFns,
  svc,
  writeAshScript,
  writeText,
  xl2tpd,
  callPackage,
}:
{
  lns,
  ppp-options,
  lcpEcho,
  username,
  password,
  debug,
}:
let
  name = "${lns}.l2tp";
  common = callPackage ./common.nix { inherit svc; };

  conf = writeText "xl2tpd.conf" ''
    [lac upstream]
    lns = ${lns}
    require authentication = no
    pppoptfile = /run/${name}/ppp-options
    autodial = yes
    redial = yes
    redial timeout = 1
    max redials = 2 # this gives 1 actual retry, as xl2tpd can't count
  '';
  control = "/run/${name}/control";
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
    touch ${control}
    exec ${xl2tpd}/bin/xl2tpd -D -p /run/${name}/${name}.pid -c ${conf} -C ${control} 
  '';
}
