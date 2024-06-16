{
  liminix
, uevent-watch
, serviceFns
, lib }:
{
  serviceName, terms, symlink
}:
let
  inherit (liminix.services) longrun;
  inherit (lib.attrsets) collect mapAttrsRecursive;
  inherit (lib.strings) concatStringsSep;
  stringify = attrs :
    concatStringsSep " "
      (collect lib.isString
        (mapAttrsRecursive
          (path : value : "${concatStringsSep "." path}=${value}")
          attrs));
  termsString = stringify terms;
in longrun {
  name = "watch-for-${serviceName}";
  restart-on-upgrade = true;
  run = "${uevent-watch}/bin/uevent-watch ${if symlink != null then "-n ${symlink}" else ""} -s ${serviceName} ${termsString}";
}
