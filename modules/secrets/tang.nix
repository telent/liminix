{
  liminix, lib, json-to-fstree, serviceFns, tangc
}:
{ name, path, interval } :
let
  inherit (liminix.services) longrun;
  inherit (lib) optionalString;
in longrun {
  inherit name;
  buildInputs = [ json-to-fstree ];
  notification-fd = 10;
  run = ''
    set -e
    statedir=/run/${name}
    mkdir -p -m 0700 $statedir
    ( in_outputs ${name}
      while : ; do
        ${tangc}/bin/tangc decrypt < ${path} > $statedir/.input.json
        mv $statedir/.input.json $statedir/input.json
        ${json-to-fstree}/bin/json-to-fstree file://$statedir/input.json .
        echo ready >&10
        sleep ${builtins.toString (interval * 60)}
      done
    )
  '';
}
