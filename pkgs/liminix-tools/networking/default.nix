{
  ifwait,
  serviceFns,
}:
{
  ifup = name: ifname: ''
    . ${serviceFns}
    ${ifwait}/bin/ifwait -v ${ifname} present
    ip link set up dev ${ifname}
    (in_outputs ${name}
     echo ${ifname} > ifname
    )
  '';
}
