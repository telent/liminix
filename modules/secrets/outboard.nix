{
  liminix,
  lib,
  json-to-fstree,
  serviceFns,
}:
{
  name,
  url,
  interval,
  username,
  password,
}:
let
  inherit (liminix.services) oneshot longrun;
  inherit (lib) optionalString;
in
longrun {
  inherit name;
  buildInputs = [ json-to-fstree ];
  run = ''
    ${optionalString (username != null) ''
      export NETRC=$(mkstate ${name})/netrc
      (echo default ; echo login ${username} ; echo password ${password} ) > $NETRC
    ''}
    ( in_outputs ${name}
      while : ; do
        ${json-to-fstree}/bin/json-to-fstree ${url} .
        sleep ${builtins.toString (interval * 60)}
      done
    )
  '';
}
