{
  liminix, lib, http-fstree, serviceFns
}:
{ name, url, interval } :
let
  inherit (liminix.services) oneshot longrun;
in longrun {
  inherit name;
  buildInputs = [ http-fstree ];
  run = ''
    . ${serviceFns}
    ( in_outputs ${name}
      while : ; do
        ${http-fstree}/bin/http-fstree ${url} .
        sleep ${builtins.toString (interval * 60)}
      done
    )
  '';
}
