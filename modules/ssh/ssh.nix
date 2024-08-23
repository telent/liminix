{
  liminix
, dropbear
, lib
}:
{authorizedKeys, ...} @ p :
let
  name = "sshd";
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
    (lib.optional (! p.allowRoot) "-w") ++
    (lib.optional (! p.allowPasswordLogin) "-s") ++
    (lib.optional (! p.allowPasswordLoginForRoot) "-g") ++
    (lib.optional (! p.allowLocalPortForward) "-j") ++
    (lib.optional (! p.allowRemotePortForward) "-k") ++
    (lib.optional (! p.allowRemoteConnectionToForwardedPorts) "-a") ++
    (lib.optionals (authorizedKeys != null)
      ["-U" "/run/${name}/authorized_keys/%n"]) ++
    [(if p.address != null
      then "-p ${p.address}:${p.port}"
      else "-p ${builtins.toString p.port}")] ++
    [p.extraConfig];
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
