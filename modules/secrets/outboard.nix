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
  tlsCaCertificate,
  tlsCertificate,
  tlsPrivateKey,
}:
let
  inherit (liminix.services) longrun;
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
    ${optionalString (tlsCertificate != null) ''
      export SSL_CLIENT_CERT_FILE=${tlsCertificate}
      export SSL_CLIENT_KEY_FILE=${tlsPrivateKey}
    ''}
    ${optionalString (tlsCaCertificate != null) ''
      export SSL_CA_CERT_FILE=${tlsCaCertificate}
    ''}
    ( in_outputs ${name}
      while : ; do
        ${json-to-fstree}/bin/json-to-fstree ${url} .
        sleep ${builtins.toString (interval * 60)}
      done
    )
  '';
}
