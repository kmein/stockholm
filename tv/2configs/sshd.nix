{ config, lib, pkgs, ... }:

with import <stockholm/lib>;

{
  services.openssh = {
    enable = true;
    hostKeys = [
      {
        type = "ed25519";
        path = "/etc/ssh/ssh_host_ed25519_key";
      }
    ];
  };
  tv.iptables.input-internet-accept-tcp = singleton "ssh";
}
