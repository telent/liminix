{
  wpa_passphrase = "you bring light in";
  ssid = "liminix";
  l2tp = {
    name = "abcde@a.1";
    password = "NotMyIspPassword";
  };
  root = {
    #  mkpasswd -m sha512crypt
    passwd = "$6$6pt0mpbgcB7kC2RJ$kSBoCYGyi1.qxt7dqmexLj1l8E6oTZJZmfGyJSsMYMW.jlsETxdgQSdv6ptOYDM7DHAwf6vLG0pz3UD31XBfC1";
    openssh.authorizedKeys.keys = [
    ];
  };

  lan = {
    prefix = "10.8.0";
  };

}
