{
  config,
  lib,
  pkgs,
  myvars,
  ...
}:

let
  # 通过本地 mihomo 代理 Homebrew；避免硬编码 TUNA 镜像，让 Homebrew 自己走代理访问官方源。
  inherit (myvars.networking.mihomo) httpProxy socksProxy;
  proxyLib = myvars.networking.proxy;
  homebrew_mirror_env = proxyLib.env {
    inherit httpProxy socksProxy;
    noProxyList = proxyLib.noProxyLocal;
  };
  homebrew_env_script = lib.concatStringsSep "\n" (
    lib.attrsets.mapAttrsToList (n: v: "export ${n}=${v}") homebrew_mirror_env
  );
in
{
  # git from system/common/system-packages.nix
  environment.variables = {
    TERMINFO_DIRS = map (path: path + "/share/terminfo") config.environment.profiles ++ [
      "/usr/share/terminfo"
    ];
  };
  system.activationScripts = lib.mkIf proxyLib.policy.homebrewEnv {
    homebrew.text = lib.mkBefore ''
      ${homebrew_env_script}
    '';
  };

  programs.zsh.enable = true;
  environment.shells = [ pkgs.zsh ];

  # Homebrew 仅用于无法由 Nix 提供的 cask；CLI 仍以 Nix 为准（见 system/common/system-packages.nix）。
  homebrew = {
    # Nix 管理 Homebrew，但禁用 Brewfile 模式，避免每次 `brew bundle` 很慢。
    # 仍然会用 `brew install` 确保 brews/casks 存在。
    enable = true;
    global = {
      brewfile = false;
    };
    onActivation = {
      autoUpdate = false; # faster rebuild; run brew update when needed
      upgrade = false; # don't upgrade on every rebuild; run brew upgrade manually
      cleanup = "none"; # 避免每次重建做大量清理；需要时手动 `brew cleanup`
    };

    # Mac App Store 应用（会拖慢 rebuild；需要时再添加）
    # Office 组件（Word/Excel/PPT/365 套件）用 mas 安装易报错，请从 App Store 手动安装
    masApps = { };

    # 目前不需要第三方 formulae，去掉额外 taps 以加快 brew 元数据处理；
    # 如果未来需要 yabai 等，再重新启用。
    taps = [ ];

    # CLI 工具改由 Nix 提供（见 system/common/system-packages.nix）；Homebrew 仅负责 GUI casks。
    brews = [ ];

    # 256G SSD 策略：重量级 GUI 由 Homebrew cask 管理，减少 Nix store 代际占用。
    casks = [
      "chatgpt"
      "google-chrome"
      "telegram"
    ];
  };
}
