{
  liminix, lib, lim, s6, s6-rc, watch-outputs
}:
{ watch, service, action } :
let
  inherit (liminix.services) oneshot longrun;
  inherit (builtins) toString;
  inherit (service) name;
  watcher = let name' = "check-${name}"; in longrun {
    name = name';
    run = ''
      dir=/run/service/${name}
      echo waiting for $dir
      if test -e $dir/notification-fd; then flag="-U"; else flag="-u"; fi
      ${s6}/bin/s6-svwait $flag /run/service/${name} || exit
      PATH=${s6-rc}/bin:${s6}/bin:$PATH
      ${watch-outputs}/bin/watch-outputs -r ${name} ${watch.service} ${lib.concatStringsSep " " watch.paths}
    '';
  };
in service.overrideAttrs(o: {
  buildInputs =  (lim.orEmpty o.buildInputs) ++ [ watcher ];
  dependencies = (lim.orEmpty o.dependencies) ++ [ watcher ];
})
