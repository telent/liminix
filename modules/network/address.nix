{
  liminix
, serviceFns
, lib
}:
{interface, family, address, prefixLength} :
let
  inherit (liminix.services) oneshot;
  # rather depending on the assumption that nobody will
  # ever add two addresses which are the same but with different
  # prefixes, or the same but different protocols
  name = "${interface.name}.a.${address}";
  up = ''
    dev=$(output ${interface} ifname)
    ip address add ${address}/${toString prefixLength} dev $dev
    (in_outputs ${name}
     echo ${address} > address
     echo ${toString prefixLength} > prefix-length
     echo ${family} > family
     echo $dev > ifname
    )
  '';
in oneshot {
  inherit name up;
  down = "true";                # this has been broken for ~ ages
  dependencies = [ interface ];
}
