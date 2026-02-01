{ config, pkgs, myvars, ... }:

let
  configDir = "${config.xdg.configHome}/mihomo";
  # 优先级: config.local.yaml > config.yaml > config.yaml.example（模板）
  configSource =
    if builtins.pathExists ./mihomo/config.local.yaml
    then ./mihomo/config.local.yaml
    else if builtins.pathExists ./mihomo/config.yaml
    then ./mihomo/config.yaml
    else ./mihomo/config.yaml.example;
  inherit (myvars.networking.mihomo) httpProxy socksProxy;
in
{
  home.packages = [ pkgs.mihomo ];

  # 环境变量：使 CLI 工具（curl、wget、git 等）使用 mihomo 代理
  # no_proxy 含国内镜像域名，确保 pip/uv/brew 直连加速
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
