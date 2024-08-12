{
  liminix, lib, http-fstree, serviceFns
}:
{ name, url, interval } :
let
  inherit (liminix.services) oneshot longrun;
in longrun {
  inherit name;
  buildInputs = [ http-fstree ];
  # this script runs once and expects the service superviser
  # to restart it
  run = ''
    . ${serviceFns}
    ( in_outputs ${name}
      ${http-fstree}/bin/http-fstree ${url} .
      sleep ${builtins.toString (interval * 60)}
    )
  '';
}
