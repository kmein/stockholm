{ config, lib, pkgs, ... }:

let
  inherit (import ../4lib { inherit pkgs lib; }) getDefaultGateway;
  inherit (lib) head;

  ip = "168.235.148.52";
in {
  imports = [
    ../2configs/base.nix
    ../2configs/os-templates/CAC-CentOS-6.5-64bit.nix
    {
      networking.interfaces.enp11s0.ip4 = [
        {
          address = ip;
          prefixLength = 24;
        }
      ];
      networking.defaultGateway = getDefaultGateway ip;
      networking.nameservers = [
        "8.8.8.8"
      ];
    }
    {
      sound.enable = false;
    }
  ];

  krebs.build.host = config.krebs.hosts.test-centos6;
}
