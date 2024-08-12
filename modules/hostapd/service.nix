{
  liminix
, hostapd
, output-template
, writeText
, lib
}:
{ interface, params} :
let
  inherit (liminix.services) longrun;
  inherit (lib) concatStringsSep mapAttrsToList;

  # This is not a friendly interface to configuring a wireless AP: it
  # just passes everything straight through to the hostapd config.
  # When we've worked out what the sensible options are to expose,
  # we'll add them as top-level attributes and rename params to
  # extraParams

  name = "${interface.name}.hostapd";
  defaults =  {
    driver = "nl80211";
    logger_syslog = "-1";
    logger_syslog_level = 1;
    ctrl_interface = "/run/hostapd";
    ctrl_interface_group = 0;
  };
  attrs = defaults // params ;
  literal_or_output = o:
    let typ =  builtins.typeOf o;
    in if typ == "string"
    then builtins.toJSON o
       else if typ == "int"
       then builtins.toJSON o
       else "output(${builtins.toJSON o.service}, ${builtins.toJSON o.path})";
  format_value = n : v:
    "${n}={{ ${literal_or_output v} }}";
  conf =
    (writeText "hostapd.conf.in"
      ((concatStringsSep
        "\n"
        (mapAttrsToList
          format_value
          attrs)) + "\n"));
in longrun {
  inherit name;
  dependencies = [ interface ];
  run = ''
    ${output-template}/bin/output-template '{{' '}}'  < ${conf}  > /run/${name}.conf
    exec ${hostapd}/bin/hostapd -i $(output ${interface} ifname)  -P /run/${name}.pid -S /run/${name}.conf
  '';
}
