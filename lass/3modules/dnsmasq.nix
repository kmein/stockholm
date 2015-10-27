{ config, lib, pkgs, ... }:

with builtins;
with lib;

let
  cfg = config.lass.dnsmasq;

  out = {
    options.lass.dnsmasq = api;
    config = mkIf cfg.enable imp;
  };

  api = {
    enable = mkEnableOption "dnsmasq";
    config = mkOption {
      type = types.str;
      #TODO: find a good default
      default = ''
      '';
      description = "configuration dnsmasq is started with";
    };
  };

  configFile = pkgs.writeText "dnsmasq.conf" cfg.config;

  imp = {
    #users.extraUsers.go = {
    #  name = "go";
    #  uid = 42774411; #genid go
    #  description = "go url shortener user";
    #  home = "/var/lib/go";
    #  createHome = true;
    #};

    systemd.services.dnsmasq = {
      description = "dnsmasq";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      path = with pkgs; [
        dnsmasq
      ];


      restartIfChanged = true;

      serviceConfig = {
        Restart = "always";
        ExecStart = "${pkgs.dnsmasq}/bin/dnsmasq -k -C ${configFile}";
      };
    };
  };

in out
