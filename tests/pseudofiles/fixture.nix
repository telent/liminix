{
  pseudofile
}: let
  inherit (pseudofile) dir;
  structure = {
    service = dir {
      s6-linux-init-runleveld = dir {
        notification-fd = { file = "3"; };
        run = {
          file = ''
           hello
           world
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
              s6-linux-init/bin/s6-linux-init-shutdownd -c  "/etc/s6-linux-init/current" -g 3000
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
              gdsgdfgsdgf
          '';
        };
      };
    };
    uncaught-logs = (dir {}) // {mode = "2750";};
  };
in pseudofile.write "pseudo.s6-init" structure
