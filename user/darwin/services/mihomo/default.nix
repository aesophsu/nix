# mihomo: package, env vars, config, launchd
# Config precedence: config.local.yaml > config.yaml > config.yaml.example

{ config, pkgs, lib, mylib, myvars, ... }:

let
  configDir = "${config.xdg.configHome}/mihomo";
  configSource = mylib.firstExistingPathOr {
    candidates = [
      ./config.local.yaml
      ./config.yaml
    ];
    default = ./config.yaml.example;
  };
  inherit (myvars.networking.mihomo) httpProxy socksProxy;
  proxyPolicy = myvars.networking.proxy.policy;
  proxyEnv = myvars.networking.proxy.env { inherit httpProxy socksProxy; };
in
{
  home.packages = [ pkgs.mihomo ];

  # Env vars so CLI (curl, wget, git, etc.) use mihomo proxy
  # no_proxy includes mirror domains so pip/uv/brew can go direct
  home.sessionVariables = lib.mkIf (proxyPolicy.cliDefault == "on") proxyEnv;

  xdg.configFile."mihomo/config.yaml" = {
    source = configSource;
  };

  launchd.agents.mihomo = {
    enable = true;
    config = {
      Label = "mihomo";
      ProgramArguments = [
        "${pkgs.mihomo}/bin/mihomo"
        "-d"
        configDir
      ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/mihomo.stdout.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/mihomo.stderr.log";
    };
  };
}
