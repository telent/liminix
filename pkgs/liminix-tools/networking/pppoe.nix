{
  liminix
, lib
, ppp
, pppoe
, writeAshScript
, serviceFns
} :
let
  inherit (liminix.services) longrun;
  inherit (lib)
    mergeDefinitions
    mkEnableOption mkOption isType types isDerivation hasAttr;
  t = {
    interface = mkOption {
      type = types.package;     # actually a service
      description = "ethernet interface to run PPPoE over";
    };
    ppp-options = mkOption {
      type = types.listOf types.str;
    };
  };
  t' = types.submodule { options = t; };
  typeChecked = type: value:
    let defs = [{ file = "pppoe.nix"; inherit value; }];
    in (lib.mergeDefinitions [ ] type defs).mergedValue;
in
params:
let
  inherit (typeChecked t' params) ppp-options interface;
  name = "${interface.device}.pppoe";
  ip-up = writeAshScript "ip-up" {} ''
    . ${serviceFns} 
    (in_outputs ${name}
     echo $1 > ifname
     echo $2 > tty
     echo $3 > speed
     echo $4 > address
     echo $5 > peer-address
     echo $DNS1 > ns1
     echo $DNS2 > ns2
    )
    echo >/proc/self/fd/10
  '';
  ip6-up = writeAshScript "ip6-up" {} ''
    . ${serviceFns} 
    (in_outputs ${name}
     echo $4 > ipv6-address
     echo $5 > ipv6-peer-address
    )
    echo >/proc/self/fd/10
  '';
  ppp-options' = ppp-options ++ [
    "ip-up-script" ip-up
    "ipv6-up-script" ip6-up
    "ipparam" name
    "nodetach"
    "usepeerdns"
    "logfd" "2"
  ];

in
longrun {
  inherit name;
  run = "${ppp}/bin/pppd pty '${pppoe}/bin/pppoe -I ${interface.device}' ${lib.concatStringsSep " " ppp-options'}" ;
  notification-fd = 10;
  dependencies = [ interface ];
}
