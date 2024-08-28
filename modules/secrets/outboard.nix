{
  liminix, lib, json-to-fstree, serviceFns
}:
{ name, url, interval } :
let
  inherit (liminix.services) oneshot longrun;
in longrun {
  inherit name;
  buildInputs = [ json-to-fstree ];
  run = ''
    . ${serviceFns}
    ( in_outputs ${name}
      while : ; do
        ${json-to-fstree}/bin/json-to-fstree ${url} .
        sleep ${builtins.toString (interval * 60)}
      done
    )
  '';
}
