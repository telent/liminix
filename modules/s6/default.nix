{ config, pkgs, ... }:
let
  inherit (pkgs)
    busybox
    execline
    s6
    s6-init-bin
    s6-linux-init
    stdenvNoCC;
  inherit (pkgs.pseudofile) dir symlink;

  s6-rc-db = pkgs.s6-rc-database.override {
    services = builtins.attrValues config.services;
  };
  s6-init-scripts = stdenvNoCC.mkDerivation {
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
  service = dir  {
    s6-linux-init-runleveld = dir {
      notification-fd = { file = "3"; };
      run = {
        file = ''
              #!${execline}/bin/execlineb -P
              ${execline}/bin/fdmove -c 2 1
              ${execline}/bin/fdmove 1 3
              ${s6}/bin/s6-ipcserver -1 -a 0700 -c 1 -- s
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
              ${busybox}/bin/getty -l ${busybox}/bin/login 115200 /dev/console
          '';
        mode = "0755";
      };
    };
    ".s6-svscan" =
      let
        quit = message: ''
              #!${execline}/bin/execlineb -P
              ${execline}/bin/redirfd -w 2 /dev/console
              ${execline}/bin/fdmove -c 1 2
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
in {
  config = {
    filesystem = dir {
      etc = dir {
        s6-rc = dir {
          compiled = symlink "${s6-rc-db}/compiled";
        };
        s6-linux-init = dir {
          current = dir {
            scripts = symlink "${s6-init-scripts}/scripts";
            env = dir {};
            run-image = dir {
              uncaught-logs = (dir {}) // {mode = "2750";};
              inherit service;
            };
          };
        };
      };
      bin = dir {
        init = symlink "${s6-init-bin}/bin/init";
      };
    };
  };
}
