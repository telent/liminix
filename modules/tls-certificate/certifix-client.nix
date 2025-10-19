{
  liminix,
  certifix-client,
  svc,
  lib,
  writeText,
  serviceFns,
}:
{
  caCertificate,
  secret,
  subject,
  serviceUrl,
}:
let
  inherit (builtins) filter isString split;
  inherit (liminix.services) oneshot;
  name = "certifix-${lib.strings.sanitizeDerivationName subject}";
  caCertFile = writeText "ca.crt" caCertificate;
  secretFile = writeText "secret" secret;
in
oneshot {
  inherit name;
  up = ''
    (in_outputs ${name}
     SSL_CERT_FILE=${caCertFile} ${certifix-client}/bin/certifix-client --subject ${subject} --secret ${secretFile} --key-out key --certificate-out cert ${serviceUrl}
    )
  '';
}
