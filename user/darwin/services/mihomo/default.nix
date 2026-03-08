# mihomo: package, config, launchd
# Config precedence: config.local.yaml > config.yaml > config.yaml.example

{ config, pkgs, mylib, ... }:

let
  configDir = "${config.xdg.configHome}/mihomo";
  configSource = mylib.firstExistingPathOr {
    candidates = [
      ./config.local.yaml
      ./config.yaml
    ];
    default = ./config.yaml.example;
  };
in
{
  home.packages = [ pkgs.mihomo ];

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
