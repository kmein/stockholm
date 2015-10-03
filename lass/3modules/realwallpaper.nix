arg@{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mkEnableOption
    mkOption
    types
    mkIf
  ;

  lpkgs = import ../5pkgs { inherit pkgs; };

  cfg = config.lass.realwallpaper;

  out = {
    options.lass.realwallpaper = api;
    config = mkIf cfg.enable imp;
  };

  api = {
    enable = mkEnableOption "realwallpaper";

    workingDir = mkOption {
      type = types.str;
      default = "/var/realwallpaper/";
    };

    nightmap = mkOption {
      type = types.str;
      default = "http://eoimages.gsfc.nasa.gov/images/imagerecords/55000/55167/earth_lights_lrg.jpg";
    };

    daymap = mkOption {
      type = types.str;
      default = "http://www.nnvl.noaa.gov/images/globaldata/SnowIceCover_Daily.png";
    };

    cloudmap = mkOption {
      type = types.str;
      default = "http://xplanetclouds.com/free/local/clouds_2048.jpg";
    };

    outFile = mkOption {
      type = types.str;
      default = "/tmp/wallpaper.png";
    };

    timerConfig = mkOption {
      type = types.unspecified;
      default = {
        OnCalendar = "*:0/15";
      };
    };

  };

  imp = {
    systemd.timers.realwallpaper = {
      description = "real wallpaper generator timer";

      timerConfig = cfg.timerConfig;
    };

    systemd.services.realwallpaper = {
      description = "real wallpaper generator";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      path = with pkgs; [
        xplanet
        imagemagick
        curl
        file
      ];

      environment = {
        working_dir = cfg.workingDir;
        nightmap_url = cfg.nightmap;
        daymap_url = cfg.daymap;
        cloudmap_url = cfg.cloudmap;
        out_file = cfg.outFile;
      };

      restartIfChanged = true;

      serviceConfig = {
        Type = "simple";
        ExecStart = "${lpkgs.realwallpaper}/realwallpaper.sh";
        User = "realwallpaper";
      };
    };

    users.extraUsers.realwallpaper = {
      uid = 2009435407; #genid realwallpaper
      home = cfg.workingDir;
      createHome = true;
    };
  };

in
out

