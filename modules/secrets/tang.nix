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
  run = ''
    statedir=/run/${name}
    mkdir -m 0700 $statedir
    ( in_outputs ${name}
      while : ; do
        ${tangc}/bin/tangc decrypt < ${path} > $statedir/input.json
        ${json-to-fstree}/bin/json-to-fstree file://$statedir/input.json .
        sleep ${builtins.toString (interval * 60)}
      done
    )
  '';
}
