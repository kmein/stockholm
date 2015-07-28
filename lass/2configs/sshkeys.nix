{ config, ... }:

{
  imports = [
    ../3modules/sshkeys.nix
  ];

  config.sshKeys.lass.pub = "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAp83zynhIueJJsWlSEykVSBrrgBFKq38+vT8bRfa+csqyjZBl2SQFuCPo+Qbh49mwchpZRshBa9jQEIGqmXxv/PYdfBFQuOFgyUq9ZcTZUXqeynicg/SyOYFW86iiqYralIAkuGPfQ4howLPVyjTZtWeEeeEttom6p6LMY5Aumjz2em0FG0n9rRFY2fBzrdYAgk9C0N6ojCs/Gzknk9SGntA96MDqHJ1HXWFMfmwOLCnxtE5TY30MqSmkrJb7Fsejwjoqoe9Y/mCaR0LpG2cStC1+37GbHJNH0caCMaQCX8qdfgMVbWTVeFWtV6aWOaRgwLrPDYn4cHWQJqTfhtPrNQ== lass@mors";

  config.sshKeys.uriel.pub = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDExWuRcltGM2FqXO695nm6/QY3wU3r1bDTyCpMrLfUSym7TxcXDSmZSWcueexPXV6GENuUfjJPZswOdWqIo5u2AXw9t0aGvwEDmI6uJ7K5nzQOsXIneGMdYuoOaAzWI8pxZ4N+lIP1HsOYttIPDp8RwU6kyG+Ud8mnVHWSTO13C7xC9vePnDP6b+44nHS691Zj3X/Cq35Ls0ISC3EM17jreucdP62L3TKk2R4NCm3Sjqj+OYEv0LAqIpgqSw5FypTYQgNByxRcIcNDlri63Q1yVftUP1338UiUfxtraUu6cqa2CdsHQmtX5mTNWEluVWO3uUKTz9zla3rShC+d3qvr lass@uriel";
}
