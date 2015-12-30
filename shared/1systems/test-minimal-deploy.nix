{ config, pkgs, lib, ... }:
{
  krebs = {
    enable = true;
    build.user = config.krebs.users.shared;
    build.host = config.krebs.hosts.test-all-krebs-modules;
  };
  # just get the system running
  boot.loader.grub.devices = ["/dev/sda"];
  fileSystems."/" = {
    device = "/dev/lol";
  };
}
