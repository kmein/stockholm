with import <stockholm/lib>;
{ config, lib, pkgs, ... }:

{
  imports = [
    <stockholm/lass>
    <stockholm/lass/2configs/baseX.nix>
    <stockholm/lass/2configs/browsers.nix>
    <stockholm/lass/2configs/mouse.nix>
    <stockholm/lass/2configs/pass.nix>
    <stockholm/lass/2configs/retiolum.nix>
    <stockholm/lass/2configs/otp-ssh.nix>
    # TODO fix krebs.git.rules.[definition 2-entry 2].lass not defined
    #<stockholm/lass/2configs/git.nix>
    #<stockholm/lass/2configs/dcso-vpn.nix>
    <stockholm/lass/2configs/virtualbox.nix>
    <stockholm/lass/2configs/dcso-dev.nix>
    <stockholm/lass/2configs/steam.nix>
    <stockholm/lass/2configs/rtl-sdr.nix>
    <stockholm/lass/2configs/backup.nix>
    {
      services.xserver.dpi = 200;
      fonts.fontconfig.dpi = 200;
      lass.fonts.regular = "xft:Hack-Regular:pixelsize=22,xft:Symbola";
      lass.fonts.bold =    "xft:Hack-Bold:pixelsize=22,xft:Symbola";
      lass.fonts.italic =  "xft:Hack-RegularOblique:pixelsize=22,xft:Symbol";
    }
    { #TAPIR, AGATIS, sentral, a3 - foo
      services.redis.enable = true;
    }
    {
      krebs.fetchWallpaper = {
        enable = true;
        url = "http://i.imgur.com/0ktqxSg.png";
        maxTime = 9001;
      };
    }
    {
      #urban terror port
      krebs.iptables.tables.filter.INPUT.rules = [
        { predicate = "-p tcp --dport 27960"; target = "ACCEPT"; }
        { predicate = "-p udp --dport 27960"; target = "ACCEPT"; }
      ];
    }
  ];
  krebs.build.host = config.krebs.hosts.helios;

  krebs.git.rules = [
    {
      user = [ config.krebs.users.lass-helios ];
      repo = [ config.krebs.git.repos.stockholm ];
      perm = with git; push "refs/heads/*" [ fast-forward non-fast-forward create delete merge ];
    }
    {
      lass.umts = {
        enable = true;
        modem = "/dev/serial/by-id/usb-Lenovo_F5521gw_2C7D8D7C35FC7040-if09";
        initstrings = ''
          Init1 = AT+CFUN=1
          Init2 = AT+CGDCONT=1,"IP","pinternet.interkom.de","",0,0
        '';
      };
    }
  ];

  environment.systemPackages = with pkgs; [
    ag
    vim
    git
    rsync
    hashPassword
    thunderbird
    dpass
  ];

  users.users = {
    root.openssh.authorizedKeys.keys = [
      config.krebs.users.lass-helios.pubkey
    ];
  };

  services.tlp.enable = true;

  networking.hostName = lib.mkForce "BLN02NB0162";

  security.pki.certificateFiles = [
    (pkgs.fetchurl { url = "http://pki.dcso.de/ca/PEM/DCSOCAROOTC1G1.pem"; sha256 = "006j61q2z44z6d92638iin6r46r4cj82ipwm37784h34i5x4mp0d"; })
    (pkgs.fetchurl { url = "http://pki.dcso.de/ca/PEM/DCSOCAROOTC2G1.pem"; sha256 = "1nkd1rjcn02q9xxjg7sw79lbwy08i7hb4v4pn98djknvcmplpz5m"; })
    (pkgs.fetchurl { url = "http://pki.dcso.de/ca/PEM/DCSOCAROOTC3G1.pem"; sha256 = "094m12npglnnv1nf1ijcv70p8l15l00id44qq7rwynhcgxi5539i"; })

    (pkgs.fetchurl { url = "http://pki.dcso.de/ca/PEM/DCSOCACOMPC2G1.pem"; sha256 = "1anfncdf5xsp219kryncv21ra87flpzcjwcc85hzvlwbxhid3g4x"; })
    (pkgs.fetchurl { url = "http://pki.dcso.de/ca/PEM/DCSOCACOMPC3G1.pem"; sha256 = "035kkfizyl5dndj7rhvmy91rr75lakqbqgjx4dpiw0kqq369mz8r"; })
    (pkgs.fetchurl { url = "http://pki.dcso.de/ca/PEM/DCSOCAIDENC2G1.pem"; sha256 = "14fpzx1qjs9ws9sz0y7pb6j40336xlckkqcm2rc5j86yn7r22lp7"; })
    (pkgs.fetchurl { url = "http://pki.dcso.de/ca/PEM/DCSOCAIDENC3G1.pem"; sha256 = "1yjl3kyw4chc8vw7bnqac2h9vn8dxryw7lr7i03lqi9sdvs4108s"; })
  ];

  programs.adb.enable = true;
  users.users.mainUser.extraGroups = [ "adbusers" "docker" ];

  services.printing.drivers = [ pkgs.postscript-lexmark ];

  services.logind.extraConfig = ''
    HandleLidSwitch=ignore
  '';

  virtualisation.docker.enable = true;
}
