{ config, pkgs, ... }:

## TODO sort and split up
{
  environment.systemPackages = with pkgs; [
    aria2
    gnupg1compat
    htop
    i3lock
    mosh
    pass
    pavucontrol
    pv
    pwgen
    remmina
    silver-searcher
    wget
    xsel
    youtube-dl
  ];
}
