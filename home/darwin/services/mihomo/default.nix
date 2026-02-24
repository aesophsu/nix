# mihomo: package, env vars, config, launchd
# Config precedence: agenix secret > config.local.yaml > config.yaml > config.yaml.example

{ config, lib, pkgs, mylib, myvars, ... }:

let
  configDir = "${config.xdg.configHome}/mihomo";
  hasAgeMihomoConfig = lib.hasAttrByPath [ "age" "secrets" "mihomo-config" "path" ] config;
  fallbackConfigSource = mylib.firstExistingPathOr {
    candidates = [
      ./config.local.yaml
      ./config.yaml
    ];
    default = ./config.yaml.example;
  };
  configSource = if hasAgeMihomoConfig then config.age.secrets."mihomo-config".path else fallbackConfigSource;
  inherit (myvars.networking.mihomo) httpProxy socksProxy;
  proxyEnv = myvars.networking.proxy.env { inherit httpProxy socksProxy; };
in
{
  home.packages = [ pkgs.mihomo ];

  # Env vars so CLI (curl, wget, git, etc.) use mihomo proxy
  # no_proxy includes mirror domains so pip/uv/brew can go direct
  home.sessionVariables = proxyEnv;

  xdg.configFile."mihomo/config.yaml" = lib.mkIf (!hasAgeMihomoConfig) { source = fallbackConfigSource; };

  launchd.agents.mihomo = {
    enable = true;
    config = {
      Label = "mihomo";
      ProgramArguments = [
        "${pkgs.mihomo}/bin/mihomo"
        "-d"
        configDir
      ] ++ lib.optionals hasAgeMihomoConfig [
        "-f"
        configSource
      ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/mihomo.stdout.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/mihomo.stderr.log";
    };
  };
}
