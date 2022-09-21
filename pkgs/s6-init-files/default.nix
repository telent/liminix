{
  execline
, s6
, s6-linux-init
, s6-rc
, pseudofile
, lib
, stdenvNoCC
, busybox
} :
let
  initscripts = stdenvNoCC.mkDerivation {
    name = "s6-scripts";
    src = ./scripts;
    phases = ["unpackPhase" "installPhase" ];
    buildInputs = [busybox];
    installPhase = ''
      mkdir $out
      cp -r $src $out/scripts
      chmod -R +w $out
      patchShebangs $out/scripts
    '';
  };
  dir = contents: { type = "d"; inherit contents; };
  symlink = target: { type = "s"; inherit target; };
  hpr = arg: "#!${execline}/bin/execlineb -S0\n${s6-linux-init}/bin/s6-linux-init-hpr ${arg} \$@";
  bin = dir {
    shutdown = symlink "${s6-linux-init}/bin/s6-linux-init-shutdown";
    telinit = symlink "${s6-linux-init}/bin/s6-linux-init-telinit";
    reboot = { type="f"; file = hpr "-r"; mode="0755"; };
    poweroff = { type="f"; file = hpr "-p"; mode="0755"; };
    halt = { type="f"; file = hpr "-h"; mode="0755"; };
    init = {
      type="f"; mode="0755";
      file = "#!${execline}/bin/execlineb -S0\n${s6-linux-init}/bin/s6-linux-init -c /etc/s6-linux-init/current -m 0022 -p ${lib.makeBinPath [execline s6-linux-init s6-rc]}:/usr/bin:/bin -d /dev -- \"\\$@\"";
    };
  };
  scripts = symlink "${initscripts}/scripts";
  env = dir {};
  run-image = dir {
    service = dir {
      s6-linux-init-runleveld = dir {
        notification-fd = { file = "3"; };
        run = {
          file = ''
              #!${execline}/bin/execlineb -P
              ${execline}/bin/fdmove -c 2 1
              ${execline}/bin/bin/fdmove 1 3
              ${s6}/s6-ipcserver -1 -a 0700 -c 1 -- s
              ${s6}/bin/s6-sudod -dt30000 -- "/etc/s6-linux-init/current"/scripts/runlevel
            '';
          mode = "0755";
        };
      };
      s6-linux-init-shutdownd = dir {
        fifo = {
          type = "i";
          subtype = "f";
          mode = "0600";
        };
        run = {
          file = ''
              #!${execline}/bin/execlineb -P
              ${s6-linux-init}/bin/s6-linux-init-shutdownd -c  "/etc/s6-linux-init/current" -g 3000
            '';
          mode = "0755";
        };

      };
      s6-svscan-log = dir {
        fifo = {
          type = "i";
          subtype = "f";
          mode = "0600";
        };
        notification-fd = { file = "3"; };
        run = {
          file = ''
              #!${execline}/bin/execlineb -P
              ${execline}/bin/redirfd -w 1 /dev/null
              ${execline}/bin/redirfd -rnb 0 fifo
              ${s6}/bin/s6-log -bpd3 -- t /run/uncaught-logs
          '';
          mode = "0755";
        };
      };
      getty = dir {
        run = {
          file = ''
              #!${execline}/bin/execlineb -P
              ${busybox}/bin/getty -l ${busybox}/bin/login 38400 /dev/console
          '';
          mode = "0755";
        };
      };
      ".s6-svscan" =
        let
          quit = message: ''
              #!${execline}/bin/execlineb -P
              ${execline}/bin/redirfd -w 2 /dev/console
              ${execline}/bin/bin/fdmove -c 1 2
              ${execline}/bin/foreground { ${s6-linux-init}/bin/s6-linux-init-echo -- ${message} }
              ${s6-linux-init}/bin/s6-linux-init-hpr -fr
            '';
          shutdown = action: ''
              #!${execline}/bin/execlineb -P
              ${s6-linux-init}/bin/s6-linux-init-hpr -a #{action} -- now
            '';
          empty = "#!${execline}/bin/execlineb -P\n";
        in dir {
          crash = {
            file = quit "s6-svscan crashed. Rebooting.";
            mode = "0755";
          };
          finish = {
            file = quit "s6-svscan exited. Rebooting.";
            mode = "0755";
          };
          SIGINT = {
            file = shutdown "-r";
            mode = "0755";
          };
          SIGPWR = {
            file = shutdown "-p";
            mode = "0755";
          };
          SIGQUIT = {
            file = empty;
            mode = "0755";
          };
          SIGTERM = {
            file = empty;
            mode = "0755";
          };
          SIGUSR1 = {
            file = shutdown "-p";
            mode = "0755";
          };
          SIGUSR2 = {
            file = shutdown "-h";
            mode = "0755";
          };
          SIGWINCH = {
            file = empty;
            mode = "0755";
          };

        };
    };
    uncaught-logs = (dir {}) // {mode = "2750";};
  };
  structure = { etc = dir { s6-linux-init = dir { current = dir {
    inherit bin scripts env run-image;
  };};};};

in pseudofile "pseudo.s6-init" structure
