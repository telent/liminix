{ config, pkgs, ... }:
{
  config = {
    programs.busybox = {
      options = {
        # schnapps is a shell script that needs
        # [ command
        # find -maxdepth  -mindepth
        # head -c
        # echo -n
        ASH_TEST = "y";
        FEATURE_FIND_MAXDEPTH = "y";
        FEATURE_FANCY_HEAD = "y";
        FEATURE_FANCY_ECHO = "y";
      };
    };
    defaultProfile.packages = [ pkgs.schnapps ];
  };
}
