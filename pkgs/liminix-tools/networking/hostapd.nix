# This is not a friendly interface to configuring a wireless AP: it
# just passes everything straight through to the hostapd config.  When
# we've worked out what the sensible options are to expose, we'll add
# them as top-level attributes and rename params to extraParams

{
  liminix
, hostapd
, lib
, writeText
}:
interface:
{
  params ? {}
}:
let
  inherit (liminix.services) longrun;
  inherit (lib) concatStringsSep mapAttrsToList;
  inherit (builtins) toString;

  name = "${interface.device}.hostapd";
  defaults =  {
    driver = "nl80211";
    logger_syslog = "-1";
    logger_syslog_level = 1;
    ctrl_interface = "/run/hostapd";
    ctrl_interface_group = 0;
  };

  conf = writeText "hostapd.conf"
    (concatStringsSep
      "\n"
      (mapAttrsToList
        (name: value: "${name}=${toString value}")
        (defaults // params)));
in longrun {
  inherit name;
  run = "${hostapd}/bin/hostapd -d -i ${interface.device}  -P /run/hostapd.pid -S ${conf}";
}
