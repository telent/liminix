{
  liminix
, dropbear
, lib
}:
{
  address,
  allowLocalPortForward,
  allowPasswordLogin,
  allowPasswordLoginForRoot,
  allowRemoteConnectionToForwardedPorts,
  allowRemotePortForward,
  allowRoot,
  authorizedKeys,
  port,
  extraConfig
}:
let
  name = "sshd";
  inherit (builtins) toString;
  inherit (liminix.services) longrun;
  inherit (lib) concatStringsSep mapAttrs mapAttrsToList;
  options =
    [
      "-e" #  pass environment to child
      "-E" #  log to stderr
      "-R" #  create hostkeys if needed
      "-P /run/dropbear.pid"
      "-F" #  don't fork into background
    ] ++
    (lib.optional (! allowRoot) "-w") ++
    (lib.optional (! allowPasswordLogin) "-s") ++
    (lib.optional (! allowPasswordLoginForRoot) "-g") ++
    (lib.optional (! allowLocalPortForward) "-j") ++
    (lib.optional (! allowRemotePortForward) "-k") ++
    (lib.optional (! allowRemoteConnectionToForwardedPorts) "-a") ++
    (lib.optionals (authorizedKeys != null)
      ["-U" "/run/${name}/authorized_keys/%n"]) ++
    [(if address != null
      then "-p ${address}:${toString port}"
      else "-p ${toString port}")] ++
    [extraConfig];
  authKeysConcat =
    if authorizedKeys != null
    then mapAttrs
      (n : v : concatStringsSep "\\n" v)
      authorizedKeys
    else {};
in
longrun {
  inherit name;
  # we need /run/dropbear to point to hostkey storage, as that
  # pathname is hardcoded into the binary.
  # env -i clears the environment so we don't pass anything weird to
  # ssh sessions
  run = ''
    ln -s $(mkstate dropbear) /run
    mkdir -p /run/${name}/authorized_keys
    ${concatStringsSep "\n"
      (mapAttrsToList
        (n : v : "echo -e '${v}' > /run/${name}/authorized_keys/${n} ")
        authKeysConcat
      )
     }
    . /etc/profile # sets PATH but do we need this?  it's the same file as ashrc
    exec env -i ENV=/etc/ashrc PATH=$PATH ${dropbear}/bin/dropbear ${concatStringsSep " " options}
  '';
}
