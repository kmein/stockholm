{ config, pkgs, ... }: with import <stockholm/lib>;

let

  hostname = config.networking.hostName;

  sourceRepos = [
    "http://cgit.enklave.r/stockholm"
    "http://cgit.gum.r/stockholm"
    "http://cgit.hotdog.r/stockholm"
    "http://cgit.ni.r/stockholm"
    "http://cgit.prism.r/stockholm"
  ];

  build = pkgs.writeDash "build" ''
    set -eu
    export USER="$1"
    export SYSTEM="$2"
    $(nix-build $USER/krops.nix --no-out-link --argstr name "$SYSTEM" --argstr target "$HOME/stockholm-build" -A ci)
  '';


in
{
  networking.firewall.allowedTCPPorts = [ 80 ];
  services.nginx = {
    enable = true;
    virtualHosts.build = {
      serverAliases = [ "build.${hostname}.r" ];
      locations."/".extraConfig = ''
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_pass http://127.0.0.1:${toString config.krebs.buildbot.master.web.port};
      '';
    };
  };

  krebs.buildbot.master = {
    slaves = {
      testslave = "lasspass";
    };
    change_source.stockholm = concatMapStrings (repo: ''
      cs.append(
          changes.GitPoller(
              "${repo}",
              workdir='stockholm${elemAt(splitString "." repo) 1}', branches=True,
              project='stockholm',
              pollinterval=10
          )
      )
    '') sourceRepos;
    scheduler = {
      auto-scheduler = ''
        sched.append(
              schedulers.SingleBranchScheduler(
                  change_filter=util.ChangeFilter(branch_re=".*"),
                  treeStableTimer=60,
                  name="build-all-branches",
                  builderNames=[
                      "hosts",
                  ]
              )
        )
      '';
      force-scheduler = ''
        sched.append(
            schedulers.ForceScheduler(
                  name="hosts",
                  builderNames=[
                      "hosts",
                  ]
            )
        )
      '';
    };
    builder_pre = ''
      # prepare grab_repo step for stockholm
      grab_repo = steps.Git(
          repourl=util.Property('repository', 'http://cgit.hotdog.r/stockholm'),
          mode='full',
          submodules=True,
      )
    '';
    builder = {
      hosts = ''
        from buildbot import interfaces
        from buildbot.steps.shell import ShellCommand

        class StepToStartMoreSteps(ShellCommand):
            def __init__(self, **kwargs):
                ShellCommand.__init__(self, **kwargs)

            def addBuildSteps(self, steps_factories):
                for sf in steps_factories:
                    step = interfaces.IBuildStepFactory(sf).buildStep()
                    step.setBuild(self.build)
                    step.setBuildSlave(self.build.slavebuilder.slave)
                    step_status = self.build.build_status.addStepWithName(step.name)
                    step.setStepStatus(step_status)
                    self.build.steps.append(step)

            def start(self):
                props = self.build.getProperties()
                hosts = json.loads(props.getProperty('hosts_json'))
                for host in hosts:
                    user = hosts[host]['owner']

                    self.addBuildSteps([steps.ShellCommand(
                        name=str(host),
                        env={
                          "NIX_PATH": "secrets=/var/src/stockholm/null:stockholm=./:/var/src",
                          "NIX_REMOTE": "daemon",
                        },
                        command=[
                          "${build}", user, host
                        ],
                        timeout=90001,
                        workdir='build', # TODO figure out why we need this?
                    )])

                ShellCommand.start(self)


        f = util.BuildFactory()
        f.addStep(grab_repo)

        f.addStep(steps.SetPropertyFromCommand(
            env={
              "NIX_PATH": "secrets=/var/src/stockholm/null:stockholm=./:/var/src",
              "NIX_REMOTE": "daemon",
            },
            name="get_hosts",
            command=["nix-instantiate", "--json", "--strict", "--eval", "-E", """
                with import <nixpkgs> {};
                let
                  eval-config = cfg:
                    import <nixpkgs/nixos/lib/eval-config.nix> {
                      modules = [
                        (import cfg)
                      ];
                    }
                  ;

                  system = eval-config ./krebs/1systems/hotdog/config.nix; # TODO put a better config here

                  ci-systems = lib.filterAttrs (_: v: v.ci) system.config.krebs.hosts;

                  filtered-attrs = lib.mapAttrs ( n: v: {
                    owner = v.owner.name;
                  }) ci-systems;

                in filtered-attrs
            """],
            property="hosts_json"
        ))
        f.addStep(StepToStartMoreSteps(command=["echo"])) # TODO remove dummy command from here

        bu.append(
            util.BuilderConfig(
                name="hosts",
                slavenames=slavenames,
                factory=f
            )
        )
      '';
    };
    enable = true;
    web.enable = true;
    irc = {
      enable = true;
      nick = "build|${hostname}";
      server = "irc.r";
      channels = [ "noise" "xxx" ];
      allowForce = true;
    };
    extraConfig = ''
      c['buildbotURL'] = "http://build.${hostname}.r/"
    '';
  };

  krebs.buildbot.slave = {
    enable = true;
    masterhost = "localhost";
    username = "testslave";
    password = "lasspass";
    packages = with pkgs; [ gnumake jq nix populate gnutar lzma gzip ];
  };
}
