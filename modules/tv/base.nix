{ config, pkgs, ... }:

{
  time.timeZone = "Europe/Berlin";

  # TODO check if both are required:
  nix.chrootDirs = [ "/etc/protocols" pkgs.iana_etc.outPath ];

  nix.trustedBinaryCaches = [
    "https://cache.nixos.org"
    "http://cache.nixos.org"
    "http://hydra.nixos.org"
  ];

  nix.useChroot = true;
}
