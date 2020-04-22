{ config, lib, pkgs, options, ... }:

with import <stockholm/lib>;
let
  cfg = config.krebs.rtorrent;
  webcfg = config.krebs.rtorrent.web;
  rucfg = config.krebs.rtorrent.rutorrent;

  nginx-user = config.services.nginx.user;
  nginx-group = config.services.nginx.group;
  fpm-socket = config.services.phpfpm.pools.rutorrent.socket;

  webdir = rucfg.webdir;
  systemd-logfile = cfg.workDir + "/rtorrent-systemd.log";

  # rutorrent requires a couple of binaries to be available to either the
  # rtorrent process or to phpfpm

  rutorrent-deps = with pkgs; [ curl php coreutils procps ffmpeg mediainfo ] ++
    (if (config.nixpkgs.config.allowUnfree or false) then
      trace "enabling unfree packages for rutorrent" [ unrar unzip ] else
      trace "not enabling unfree packages for rutorrent because allowUnfree is unset" []);

  configFile = pkgs.writeText "rtorrent-config" ''
    # THIS FILE IS AUTOGENERATED
    ${optionalString (cfg.listenPort != null) ''
      port_range = ${toString cfg.listenPort}-${toString cfg.listenPort}
      port_random = no
    ''}

    ${optionalString (cfg.watchDir != null) ''
      directory.watch.added = "${cfg.watchDir}", load.start_verbose
    ''}

    directory = ${cfg.downloadDir}
    session = ${cfg.sessionDir}

    ${optionalString (cfg.enableXMLRPC ) ''
      # prepare socket and set permissions. rtorrent user is part of group nginx
      # TODO: configure a shared torrent group
      execute.nothrow = rm,${cfg.xmlrpc-socket}
      scgi_local = ${cfg.xmlrpc-socket}
      schedule = scgi_permission,0,0,"execute.nothrow=chmod,\"ug+w,o=\",${cfg.xmlrpc-socket}"
    ''}

    system.file.allocate.set = ${if cfg.preAllocate then "yes" else "no"}

    # Prepare systemd logging
    log.open_file = "rtorrent-systemd", ${systemd-logfile}
    log.add_output = "warn", "rtorrent-systemd"
    log.add_output = "notice", "rtorrent-systemd"
    log.add_output = "info", "rtorrent-systemd"
    # log.add_output = "debug", "rtorrent-systemd"
    ${cfg.extraConfig}
  '';

  out = {
    options.krebs.rtorrent = api;
    # This only works because none of the attrsets returns the same key
    config = with lib; mkIf cfg.enable (lib.mkMerge [
      (lib.mkIf webcfg.enable rpcweb-imp)
      # only build rutorrent-imp if webcfg is enabled as well
      (lib.mkIf (webcfg.enable && rucfg.enable) rutorrent-imp)
      imp
    ]);
  };

  api = {
    enable = mkEnableOption "rtorrent";

    web = {
      # configure NGINX to provide /RPC2 for listen address
      # authentication also applies to rtorrent.rutorrent
      enable = mkEnableOption "rtorrent nginx web RPC";

      addr = mkOption {
        type = types.addr4;
        default = "0.0.0.0";
        description = ''
          the address to listen on
          default is 0.0.0.0
        '';
      };

      port = mkOption {
        type = types.nullOr types.int;
        description =''
          nginx listen port for rtorrent
        '';
        default = 8006;
      };

      basicAuth = mkOption {
        type = types.attrsOf types.str ;
        description = ''
          basic authentication to be used. If unset, no authentication will be
          enabled.

          Refer to `services.nginx.virtualHosts.<name>.basicAuth`
        '';
        default = {};
      };
    };

    rutorrent = {
      enable = mkEnableOption "rutorrent"; # requires rtorrent.web.enable

      package = mkOption {
        type = types.package;
        description = ''
          path to rutorrent package. When using your own ruTorrent package,
          scgi_port and scgi_host will be patched on startup.
        '';
        default = pkgs.rutorrent;
      };

      webdir = mkOption {
        type = types.path;
        description = ''
          rutorrent php files will be written to this folder.
          when using nginx, be aware that the the folder should be readable by nginx.
          because rutorrent does not hold mutable data in a separate folder
          these files must be writable.
        '';
        default = "/var/lib/rutorrent";
      };

    };

    package = mkOption {
      type = types.package;
      default = pkgs.rtorrent;
    };

    # TODO: enable xmlrpc with web.enable
    enableXMLRPC = mkEnableOption "rtorrent xmlrpc via socket";
    xmlrpc-socket = mkOption {
      type = types.str;
      description = ''
        enable xmlrpc at given socket. Required for web-interface.

        for documentation see:
        https://github.com/rakshasa/rtorrent/wiki/RPC-Setup-XMLRPC
      '';
      default = cfg.workDir + "/rtorrent.sock";
    };

    preAllocate = mkOption {
      type = types.bool;
      description = ''
        Pre-Allocate torrent files
      '';
      default = true;
    };

    downloadDir = mkOption {
      type = types.path;
      description = ''
        directory where torrents are stored
      '';
      default = cfg.workDir + "/downloads";
    };

    sessionDir = mkOption {
      type = types.path;
      description = ''
        directory where torrent progress is stored
      '';
      default = cfg.workDir + "/rtorrent-session";
    };

    watchDir = mkOption {
      type = with types; nullOr str;
      description = ''
        directory to watch for torrent files.
        If unset, no watch directory will be configured
      '';
      default = null;
    };

    listenPort = mkOption {
      type = with types; nullOr int;
      description =''
        listening port. if you want multiple ports, use extraConfig port_range
      '';
    };

    extraConfig = mkOption {
      type = types.lines;
      description = ''
        config to be placed into ${cfg.workDir}/.rtorrent.rc

        see ${cfg.package}/share/doc/rtorrent/rtorrent.rc
      '';
      example = literalExample ''
        log.execute = ${cfg.workDir}/execute.log
        log.xmlrpc = ${cfg.workDir}/xmlrpc.log
      '';
      default = "";
    };

    user = mkOption {
      description = ''
        user which will run rtorrent. if kept default a new user will be created
      '';
      type = types.str;
      default = "rtorrent";
    };

    workDir = mkOption {
      description = ''
        working directory. rtorrent will search in HOME for `.rtorrent.rc`
      '';
      type = types.str;
      default = "/var/lib/rtorrent";
    };

  };

  imp = {
    systemd.services = {
      rtorrent-daemon = {
        description = "rtorrent headless";
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
        restartIfChanged = true;
        serviceConfig = {
          Type = "forking";
          ExecStartPre = pkgs.writeDash "prepare-folder" ''
            mkdir -p ${cfg.workDir} ${cfg.sessionDir}
            chmod 770 ${cfg.workDir} ${cfg.sessionDir}
            touch ${systemd-logfile}
            cp -f ${configFile} ${cfg.workDir}/.rtorrent.rc
          '';
          ExecStart = "${pkgs.tmux}/bin/tmux new-session -s rt -n rtorrent -d 'PATH=/bin:/usr/bin:${makeBinPath rutorrent-deps} ${cfg.package}/bin/rtorrent'";
          Restart = "always";
          RestartSec = "10";

          ## you can simply sudo -u rtorrent tmux a if privateTmp is set to false
          ## otherwise the tmux session is stored in some private folder in /tmp
          PrivateTmp = false;

          WorkingDirectory = cfg.workDir;
          User = "${cfg.user}";
        };
      };
      rtorrent-log = {
        after = [ "rtorrent-daemon.service" ];
        bindsTo = [ "rtorrent-daemon.service" ];
        wantedBy = [ "rtorrent-daemon.service" ];
        serviceConfig = {
          ExecStart = "${pkgs.coreutils}/bin/tail -f ${systemd-logfile}";
          User = "${cfg.user}";
        };
      };
    } // (optionalAttrs webcfg.enable {
      rutorrent-prepare = {
        after = [ "rtorrent-daemon.service" ];
        wantedBy = [ "rtorrent-daemon.service" ];
        serviceConfig = {
          Type = "oneshot";
          # we create the folder and set the permissions to allow nginx
          # TODO: update files if the version of rutorrent changed
          ExecStart = pkgs.writeDash "create-webconfig-dir" ''
            if [ ! -e ${webdir} ];then
              echo "creating webconfiguration directory for rutorrent: ${webdir}"
              cp -vr ${rucfg.package} ${webdir}
              echo "setting permissions for webdir to ${cfg.user}:${nginx-group}"
              chown -R ${cfg.user}:${nginx-group} ${webdir}
              chmod -R 770 ${webdir}
            else
              echo "not overwriting ${webdir}"

            fi
            echo "updating xmlrpc-socket with unix://${cfg.xmlrpc-socket}"
            sed -i -e 's#^\s*$scgi_port.*#$scgi_port = 0;#' \
                -e 's#^\s*$scgi_host.*#$scgi_host = "unix://${cfg.xmlrpc-socket}";#' \
                  "${webdir}/conf/config.php"
          '';
        };
      };
    })
      // (optionalAttrs rucfg.enable { });

    users = lib.mkIf (cfg.user == "rtorrent") {
      users.rtorrent = {
        uid = genid "rtorrent";
        home = cfg.workDir;
        group = nginx-group; # required for rutorrent to work
        shell = "/bin/sh"; #required for tmux
        isSystemUser = true;
        createHome = true;
      };
      groups.rtorrent.gid = genid "rtorrent";
    };
  };

  rpcweb-imp = {
    services.nginx.enable = mkDefault true;
    services.nginx.virtualHosts.rtorrent = {
      default = mkDefault true;
      inherit (webcfg) basicAuth;
      root = optionalString rucfg.enable webdir;
      listen = [ { inherit (webcfg) addr port; } ];

      locations = {
        "/RPC2".extraConfig = ''
          include ${pkgs.nginx}/conf/scgi_params;
          scgi_param    SCRIPT_NAME  /RPC2;
          scgi_pass unix:${cfg.xmlrpc-socket};
        '';
      } // (optionalAttrs rucfg.enable {
        "~ \.php$".extraConfig = ''
          client_max_body_size 200M;
          fastcgi_split_path_info ^(.+\.php)(/.+)$;
          fastcgi_pass unix:${fpm-socket};
          try_files $uri =404;
          fastcgi_index  index.php;
          include ${pkgs.nginx}/conf/fastcgi_params;
          include ${pkgs.nginx}/conf/fastcgi.conf;
        ''; }
      );
    };
  };

  rutorrent-imp = {
    services.phpfpm = {
      pools.rutorrent = {
        user =  nginx-user;
        group =  nginx-group;
        settings = {
          "listen.owner" = nginx-user;
          "pm" = "dynamic";
          "pm.max_children" = 5;
          "pm.start_servers" = 2;
          "pm.min_spare_servers" = 1;
          "pm.max_spare_servers" = 3;
        };
        extraConfig = ''
          chdir = /
          php_admin_value[error_log] = 'stderr'
          php_admin_flag[log_errors] = on
          catch_workers_output = yes
          env[PATH] = ${makeBinPath rutorrent-deps}
        '';
      };
    };
  };
in out
