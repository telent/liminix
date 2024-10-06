
{ lib, pkgs, config, ...}:
let
  inherit (lib) mkOption types;
  inherit (pkgs) liminix;
in
{
  options = {
    system.service.tls-certificate = {
      certifix-client =  mkOption {
        type = liminix.lib.types.serviceDefn;
      };
    };
  };
  config.system.service.tls-certificate.certifix-client =
    config.system.callService ./certifix-client.nix {
      # this is probably read from files on the build machine,
      # but are not named with ...File suffix because they are
      # not files on the device (they get embedded into the store)
      caCertificate = mkOption {
        description = "CA certificate in PEM format. This must be the same CA as that which signed the certificate of the Certifix server";
        type = types.str;
      };
      secret = mkOption {
        description = "The shared secret to embed in signing request. This must match the secret configured in the Certifix service, otherwise it will refuse to sign the CSR.";
        type = types.str;
      };
      subject = mkOption {
        description = "Subject of the certificate request, as an X509 DN. The CN ('Common Name') you provide here is also used as the value of the SubjectAlternativeName extension.";
        type = types.str;
        example = "C=GB,ST=London,O=Liminix,OU=IT,CN=myhostname";
      };
      serviceUrl = mkOption {
        description = "Certifix server endpoint URL";
        type = types.str;
        example = "https://certifix.lan:19613/sign";
      };
    };

}
