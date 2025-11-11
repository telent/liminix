{
  liminix,
  lib,
  lim,
  s6,
}:
{
  service,
  interval,
  threshold,
  healthCheck,
}:
let
  inherit (liminix.services) longrun;
  inherit (builtins) toString;
  inherit (service) name;
  checker =
    let
      name' = "check-${name}";
    in
    longrun {
      name = name';
      run = ''
        fails=0
        echo waiting for /run/service/${name}
        ${s6}/bin/s6-svwait -U /run/service/${name} || exit
        while sleep ${toString interval} ; do
          ${healthCheck}
          if test $? -gt 0; then
            fails=$(expr $fails + 1)
          else
            fails=0
          fi
          echo fails $fails/${toString threshold} for ${name}
          if test "$fails" -gt "${toString threshold}" ; then
            echo time to die
            ${s6}/bin/s6-svc -r /run/service/${name}
            echo bounced
            fails=0
            echo waiting for /run/service/${name}
            ${s6}/bin/s6-svwait -U /run/service/${name}
          fi
        done
      '';
    };
in
service.overrideAttrs (o: {
  buildInputs = (lim.orEmpty o.buildInputs) ++ [ checker ];
  dependencies = (lim.orEmpty o.dependencies) ++ [ checker ];
})
