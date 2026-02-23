# mihomo: package, env vars, config, launchd
# Config precedence: config.local.yaml > config.yaml > config.yaml.example

{ config, pkgs, myvars, ... }:

let
  configDir = "${config.xdg.configHome}/mihomo";
  configSource =
    if builtins.pathExists ./config.local.yaml
    then ./config.local.yaml
    else if builtins.pathExists ./config.yaml
    then ./config.yaml
    else ./config.yaml.example;
  inherit (myvars.networking.mihomo) httpProxy socksProxy;
in
{
  home.packages = [ pkgs.mihomo ];

  # Env vars so CLI (curl, wget, git, etc.) use mihomo proxy
  # no_proxy includes mirror domains so pip/uv/brew can go direct
  home.sessionVariables = {
    http_proxy = httpProxy;
    https_proxy = httpProxy;
    all_proxy = socksProxy;
    HTTP_PROXY = httpProxy;
    HTTPS_PROXY = httpProxy;
    ALL_PROXY = socksProxy;
    no_proxy = "localhost,127.0.0.1,.local,.lan,.cn,mirror.nju.edu.cn,pypi.tuna.tsinghua.edu.cn,mirrors.ustc.edu.cn,mirrors.bfsu.edu.cn,mirrors.tuna.tsinghua.edu.cn";
    NO_PROXY = "localhost,127.0.0.1,.local,.lan,.cn,mirror.nju.edu.cn,pypi.tuna.tsinghua.edu.cn,mirrors.ustc.edu.cn,mirrors.bfsu.edu.cn,mirrors.tuna.tsinghua.edu.cn";
  };

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
