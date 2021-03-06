{ lib, ... }:
with import ../lib.nix { inherit lib; };

{
  lass.hass.config = lib.mkMerge [
    (detect_movement sensors.movement.nass lights.nass 100)
    (lightswitch switches.dimmer.nass lights.nass)
  ];
}

