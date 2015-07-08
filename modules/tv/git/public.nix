{ config, lib, pkgs, ... }:

let
  inherit (builtins) map readFile;
  inherit (lib) concatMap listToAttrs;
  # TODO lib should already include our stuff
  inherit (import ../../../lib { inherit lib pkgs; }) addNames git;

  public-git-repos = [
    (public "cgserver")
    (public "crude-mail-setup")
    (public "dot-xmonad")
    (public "hack")
    (public "load-env")
    (public "make-snapshot")
    (public "mime")
    (public "much")
    (public "nixos-infest")
    (public "nixpkgs")
    (public "painload")
    (public "regfish")
    (public' {
      name = "shitment";
      desc = "turn all the computers into one computer!";
    })
    (public "wai-middleware-time")
    (public "web-routes-wai-custom")
  ];

  users = addNames {
    tv = { pubkey = readFile <pubkeys/tv_wu.ssh.pub>; };
    lass = { pubkey = readFile <pubkeys/lass.ssh.pub>; };
    uriel = { pubkey = readFile <pubkeys/uriel.ssh.pub>; };
    makefu = { pubkey = readFile <pubkeys/makefu.ssh.pub>; };
  };

  repos = listToAttrs (map ({ repo, ... }: { name = repo.name; value = repo; }) public-git-repos);

  rules = concatMap ({ rules, ... }: rules) public-git-repos;

  public' = { name, desc }:
    let
      x = public name;
    in
    x // { repo = x.repo // { inherit desc; }; };

  public = repo-name:
    rec {
      repo = {
        name = repo-name;
        hooks = {
          post-receive = git.irc-announce {
            nick = config.networking.hostName; # TODO make this the default
            channel = "#retiolum";
            server = "ire.retiolum";
          };
        };
        public = true;
      };
      rules = with git; with users; [
        { user = tv;
          repo = [ repo ];
          perm = push "refs/*" [ non-fast-forward create delete merge ];
        }
        { user = [ lass makefu uriel ];
          repo = [ repo ];
          perm = fetch;
        }
      ];
    };

in

{
  imports = [
    ./.
  ];
  tv.git = {
    enable = true;
    inherit repos rules users;
  };
}
