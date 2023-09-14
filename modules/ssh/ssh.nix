{
  liminix
, dropbear
, serviceFns
, lib
}:
p :
let
  inherit (liminix.services) longrun;
  inherit (lib) concatStringsSep;
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
    [(if p.address != null
      then "-p ${p.address}:${p.port}"
      else "-p ${builtins.toString p.port}")] ++
    [p.extraConfig];
in
longrun {
  name = "sshd";
  # env -i clears the environment so we don't pass anything weird to
  # ssh sessions
  run = ''
    if test -d /persist; then
      mkdir -p /persist/secrets/dropbear
      ln -s /persist/secrets/dropbear /run
    else
      mkdir -p /run/dropbear
    fi
    . /etc/profile # sets PATH but do we need this?  it's the same file as ashrc
    exec env -i ENV=/etc/ashrc PATH=$PATH ${dropbear}/bin/dropbear ${concatStringsSep " " options}
  '';
}
