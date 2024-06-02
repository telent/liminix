{
  liminix
, uevent-watch
, serviceFns
, lib }:
{
  service, terms, symlink
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
  name = "watch-for-${service.name}";
  isTrigger = true;
  buildInputs = [ service ];
  run = "${uevent-watch}/bin/uevent-watch ${if symlink != null then "-n ${symlink}" else ""} -s ${service.name} ${termsString}";
}
