{
  liminix
, svc
, hostapd
, output-template
, writeText
, lib
}:
{ interface, params} :
let
  inherit (liminix.services) longrun;
  inherit (lib) concatStringsSep mapAttrsToList unique ;
  inherit (builtins) map filter attrValues length head typeOf;

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
    ctrl_interface = "/run/${name}";
    ctrl_interface_group = 0;
  };
  attrs = defaults // params ;
  literal_or_output = o: ({
    string = builtins.toJSON;
    int = builtins.toJSON;
    set = (o: "output(${builtins.toJSON o.service}, ${builtins.toJSON o.path})");
  }.${builtins.typeOf o}) o;
  format_value = n : v:
    "${n}={{ ${literal_or_output v} }}";
  conf =
    (writeText "hostapd.conf.in"
      ((concatStringsSep
        "\n"
        (mapAttrsToList
          format_value
          attrs)) + "\n"));
  service = longrun {
    inherit name;
    dependencies = [ interface ];
    run = ''
      mkdir -p /run/${name}
      chmod 0700 /run/${name}
      ${output-template}/bin/output-template '{{' '}}' < ${conf} > /run/${name}/hostapd.conf
      exec ${hostapd}/bin/hostapd -i $(output ${interface} ifname) -P /run/${name}/hostapd.pid -S /run/${name}/hostapd.conf
    '';
  };
  watch = filter (f: typeOf f == "set") (attrValues attrs);
in svc.secrets.subscriber.build {
  inherit watch;
  inherit service;
  action = "restart-all";
}
