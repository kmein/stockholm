{ config, pkgs, ... }:
with import <stockholm/lib>;

{
  services.nginx.virtualHosts.paste = {
    serverAliases = [ "p.r" ];
    locations."/".extraConfig = ''
      client_max_body_size 4G;
      proxy_set_header Host $host;
      proxy_pass http://localhost:9081;
    '';
  };
  services.nginx.virtualHosts."p.krebsco.de" = {
    enableACME = true;
    addSSL = true;
    serverAliases = [ "p.krebsco.de" ];
    locations."/".extraConfig = ''
      if ($request_method != GET) {
        return 403;
      }
      proxy_set_header Host $host;
      proxy_pass http://localhost:9081;
    '';
  };
  krebs.htgen.paste = {
    port = 9081;
    script = toString [
      "PATH=${makeBinPath [
        pkgs.nix
      ]}:$PATH"
      "STATEDIR=$HOME"
      ". ${pkgs.htgen}/examples/paste"
    ];
  };
  krebs.iptables.tables.filter.INPUT.rules = [
    { predicate = "-i retiolum -p tcp --dport 80"; target = "ACCEPT";}
    { predicate = "-i retiolum -p tcp --dport 9081"; target = "ACCEPT";}
  ];
}
