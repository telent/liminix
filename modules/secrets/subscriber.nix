{
  liminix,
  lib,
  lim,
  s6,
  s6-rc,
  watch-outputs,
  s6-rc-up-tree,
}:
{
  watch,
  service,
  action,
}:
let
  inherit (liminix.services) longrun;
  inherit (builtins) map;
  inherit (lib) optional concatStringsSep;
  inherit (service) name;

  restart-flag =
    {
      restart = "-r";
      restart-all = "-R";
      "hup" = "-s 1";
      "int" = "-s 2";
      "quit" = "-s 3";
      "kill" = "-s 9";
      "term" = "-s 15";
      "winch" = "-s 20";
      "usr1" = "-s usr1";
      "usr2" = "-s usr2";
    }
    .${action};

  watcher =
    let
      name' = "restart-${name}";
      refs = concatStringsSep " " (map (s: "${s "service"}:${s "path"}") watch);
    in
    longrun {
      name = name';
      run = ''
        dir=/run/service/${name}
        echo waiting for $dir
        if test -e $dir/notification-fd; then flag="-U"; else flag="-u"; fi
        ${s6}/bin/s6-svwait $flag /run/service/${name} || exit
        PATH=${s6-rc}/bin:${s6}/bin:${s6-rc-up-tree}/bin:$PATH
        ${watch-outputs}/bin/watch-outputs ${restart-flag} ${name} ${refs}
      '';
    };
in
service.overrideAttrs (o: {
  buildInputs = (lim.orEmpty o.buildInputs) ++ optional (watch != [ ]) watcher;
  dependencies = (lim.orEmpty o.dependencies) ++ optional (watch != [ ]) watcher;
})
