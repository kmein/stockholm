{ config, pkgs, lib, ... }:

let

  inherit (import <stockholm/lib>)
    genid
    genid_uint31
  ;
  inherit (import <stockholm/lass/2configs/websites/util.nix> {inherit lib pkgs;})
    servePage
    serveOwncloud
    serveWordpress;

  msmtprc = pkgs.writeText "msmtprc" ''
    account localhost
      host localhost
    account default: localhost
  '';

  sendmail = pkgs.writeDash "msmtp" ''
    exec ${pkgs.msmtp}/bin/msmtp --read-envelope-from -C ${msmtprc} "$@"
  '';

in {
  imports = [
    ./default.nix
    ./sqlBackup.nix
    (servePage [ "aldonasiech.com" "www.aldonasiech.com" ])
    (servePage [ "apanowicz.de" "www.apanowicz.de" ])
    (servePage [ "reich-gebaeudereinigung.de" "www.reich-gebaeudereinigung.de" ])
    (servePage [
      "freemonkey.art"
      "www.freemonkey.art"
    ])
    (serveOwncloud [ "o.ubikmedia.de" ])
    (serveWordpress [
      "ubikmedia.de"
      "nirwanabluete.de"
      "ubikmedia.eu"
      "youthtube.xyz"
      "joemisch.com"
      "weirdwednesday.de"
      "jarugadesign.de"

      "www.nirwanabluete.de"
      "www.ubikmedia.eu"
      "www.youthtube.xyz"
      "www.ubikmedia.de"
      "www.joemisch.com"
      "www.weirdwednesday.de"
      "www.jarugadesign.de"

      "aldona2.ubikmedia.de"
      "cinevita.ubikmedia.de"
      "factscloud.ubikmedia.de"
      "illucloud.ubikmedia.de"
      "joemisch.ubikmedia.de"
      "karlaskop.ubikmedia.de"
      "nb.ubikmedia.de"
      "youthtube.ubikmedia.de"
      "weirdwednesday.ubikmedia.de"
      "freemonkey.ubikmedia.de"
      "jarugadesign.ubikmedia.de"
      "crypto4art.ubikmedia.de"
      "jarugadesign.ubikmedia.de"
    ])
  ];

  services.mysql.ensureDatabases = [ "ubikmedia_de" "o_ubikmedia_de" ];
  services.mysql.ensureUsers = [
    { ensurePermissions = { "ubikmedia_de.*" = "ALL"; }; name = "nginx"; }
    { ensurePermissions = { "o_ubikmedia_de.*" = "ALL"; }; name = "nginx"; }
  ];

  services.nginx.virtualHosts."ubikmedia.de".locations."/piwika".extraConfig = ''
    try_files $uri $uri/ /index.php?$args;
  '';

  lass.mysqlBackup.config.all.databases = [
    "ubikmedia_de"
    "o_ubikmedia_de"
  ];

  services.phpfpm.phpOptions = ''
    sendmail_path = ${sendmail} -t
    upload_max_filesize = 100M
    post_max_size = 100M
    file_uploads = on
  '';

  services.nextcloud = {
    enable = true;
    hostName = "o.xanf.org";
    package = pkgs.nextcloud19;
    config = {
      adminpassFile = toString <secrets> + "/nextcloud_pw";
      overwriteProtocol = "https";
    };
    https = true;
    nginx.enable = true;
  };
  services.nginx.virtualHosts."o.xanf.org" = {
    enableACME = true;
    forceSSL = true;
  };

  # MAIL STUFF
  # TODO: make into its own module

  # workaround for android 7
  security.acme.certs."lassul.us".keyType = "rsa4096";

  services.dovecot2 = {
    enable = true;
    mailLocation = "maildir:~/Mail";
    sslServerCert = "/var/lib/acme/lassul.us/fullchain.pem";
    sslServerKey = "/var/lib/acme/lassul.us/key.pem";
  };
  krebs.iptables.tables.filter.INPUT.rules = [
    { predicate = "-p tcp --dport pop3s"; target = "ACCEPT"; }
    { predicate = "-p tcp --dport imaps"; target = "ACCEPT"; }
  ];

  krebs.exim-smarthost = {
    authenticators.PLAIN = ''
      driver = plaintext
      public_name = PLAIN
      server_condition = ''${run{/run/wrappers/bin/shadow_verify_arg ${config.lass.usershadow.pattern} $auth2 $auth3}{yes}{no}}
    '';
    authenticators.LOGIN = ''
      driver = plaintext
      public_name = LOGIN
      server_prompts = "Username:: : Password::"
      server_condition = ''${run{${config.lass.usershadow.path}/bin/verify_arg ${config.lass.usershadow.pattern} $auth1 $auth2}{yes}{no}}
    '';
    internet-aliases = [
      { from = "dma@ubikmedia.de"; to = "domsen"; }
      { from = "dma@ubikmedia.eu"; to = "domsen"; }
      { from = "mail@habsys.de"; to = "domsen"; }
      { from = "mail@habsys.eu"; to = "domsen"; }
      { from = "hallo@apanowicz.de"; to = "domsen"; }
      { from = "bruno@apanowicz.de"; to = "bruno"; }
      { from = "mail@jla-trading.com"; to = "jla-trading"; }
      { from = "jms@ubikmedia.eu"; to = "jms"; }
      { from = "ms@ubikmedia.eu"; to = "ms"; }
      { from = "ubik@ubikmedia.eu"; to = "domsen, jms, ms"; }
      { from = "kontakt@alewis.de"; to ="klabusterbeere"; }
      { from = "hallo@jarugadesign.de"; to ="kasia"; }

      { from = "testuser@lassul.us"; to = "testuser"; }
      { from = "testuser@ubikmedia.eu"; to = "testuser"; }
    ];
    sender_domains = [
      "jla-trading.com"
      "ubikmedia.eu"
      "ubikmedia.de"
      "apanowicz.de"
      "alewis.de"
      "jarugadesign.de"
    ];
    dkim = [
      { domain = "ubikmedia.eu"; }
      { domain = "apanowicz.de"; }
    ];
    ssl_cert = "/var/lib/acme/lassul.us/fullchain.pem";
    ssl_key = "/var/lib/acme/lassul.us/key.pem";
  };

  users.users.UBIK-SFTP = {
    uid = genid_uint31 "UBIK-SFTP";
    home = "/home/UBIK-SFTP";
    useDefaultShell = true;
    createHome = true;
  };

  users.users.xanf = {
    uid = genid_uint31 "xanf";
    home = "/home/xanf";
    useDefaultShell = true;
    createHome = true;
  };

  users.users.domsen = {
    uid = genid_uint31 "domsen";
    description = "maintenance acc for domsen";
    home = "/home/domsen";
    useDefaultShell = true;
    extraGroups = [ "nginx" "download" ];
    createHome = true;
  };

  users.users.bruno = {
    uid = genid_uint31 "bruno";
    home = "/home/bruno";
    useDefaultShell = true;
    createHome = true;
  };

  users.users.jla-trading = {
    uid = genid_uint31 "jla-trading";
    home = "/home/jla-trading";
    useDefaultShell = true;
    createHome = true;
  };

  users.users.jms = {
    uid = genid_uint31 "jms";
    home = "/home/jms";
    useDefaultShell = true;
    createHome = true;
  };

  users.users.ms = {
    uid = genid_uint31 "ms";
    home = "/home/ms";
    useDefaultShell = true;
    createHome = true;
  };

  users.users.testuser = {
    uid = genid_uint31 "testuser";
    home = "/home/testuser";
    useDefaultShell = true;
    createHome = true;
  };

  users.users.akayguen = {
    uid = genid_uint31 "akayguen";
    home = "/home/akayguen";
    useDefaultShell = true;
    createHome = true;
  };

  users.users.bui = {
    uid = genid_uint31 "bui";
    home = "/home/bui";
    useDefaultShell = true;
    createHome = true;
  };

  users.users.klabusterbeere = {
    uid = genid_uint31 "klabusterbeere";
    home = "/home/klabusterbeere";
    useDefaultShell = true;
    createHome = true;
  };

  users.users.kasia = {
    uid = genid_uint31 "kasia";
    home = "/home/kasia";
    useDefaultShell = true;
    createHome = true;
  };

  krebs.on-failure.plans.restic-backups-domsen = {
    journalctl = {
      lines = 1000;
    };
  };

  services.restic.backups.domsen = {
    initialize = true;
    repository = "/backups/domsen";
    passwordFile = toString <secrets> + "/domsen_backup_pw";
    timerConfig = { OnCalendar = "00:05"; RandomizedDelaySec = "5h"; };
    paths = [
      "/home/domsen/Mail"
      "/home/ms/Mail"
      "/home/klabusterbeere/Mail"
      "/home/jms/Mail"
      "/home/kasia/Mail"
      "/home/bruno/Mail"
      "/home/akayguen/Mail"
      "/backups/sql_dumps"
    ];
  };

  boot.kernel.sysctl."fs.inotify.max_user_watches" = "1048576";
  services.syncthing.declarative.folders = {
    domsen-backups = {
      path = "/backups/domsen";
      devices = [ "domsen-backup" ];
    };
    domsen-backup-srv-http = {
      path = "/srv/http";
      devices = [ "domsen-backup" ];
    };
  };

  system.activationScripts.domsen-backups = ''
    ${pkgs.coreutils}/bin/chmod 750 /backups
  '';

  krebs.permown = {
    "/backups/domsen" = {
      owner = "backup";
      group = "syncthing";
      umask = "0007";
    };
    "/srv/http" = {
      owner = "syncthing";
      group = "nginx";
      umask = "0007";
    };
  };

}

