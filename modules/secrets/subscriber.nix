{
  liminix, lib, lim, s6, s6-rc, watch-outputs
}:
{ watch, service, action } :
let
  inherit (liminix.services) oneshot longrun;
  inherit (builtins) length head toString;
  inherit (lib) unique optional;
  inherit (service) name;

  watched-services = unique (map (f: f.service) watch);
  paths = unique (map (f: f.path) watch);

  watched-service =
    if length watched-services == 0
    then null
    else if length watched-services == 1
    then head watched-services
    else throw "cannot subscribe to more than one source service for secrets";

  watcher = let name' = "restart-${name}"; in longrun {
    name = name';
    run = ''
      dir=/run/service/${name}
      echo waiting for $dir
      if test -e $dir/notification-fd; then flag="-U"; else flag="-u"; fi
      ${s6}/bin/s6-svwait $flag /run/service/${name} || exit
      PATH=${s6-rc}/bin:${s6}/bin:$PATH
      ${watch-outputs}/bin/watch-outputs -r ${name} ${watched-service.name} ${lib.concatStringsSep " " paths}
    '';
  };
in service.overrideAttrs(o: {
  buildInputs =  (lim.orEmpty o.buildInputs) ++
                 optional (watched-service != null) watcher;
  dependencies = (lim.orEmpty o.dependencies) ++
                 optional (watched-service != null)  watcher;
})
