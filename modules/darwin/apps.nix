{
  config,
  lib,
  pkgs,
  myvars,
  ...
}:

let
  inherit (myvars.networking.mihomo) httpProxy;
  no_proxy = "localhost,127.0.0.1,.local,.lan,.cn,mirrors.bfsu.edu.cn,mirrors.tuna.tsinghua.edu.cn,mirrors.ustc.edu.cn,pypi.tuna.tsinghua.edu.cn";
  homebrew_mirror_env = {
    HOMEBREW_API_DOMAIN = "https://mirrors.bfsu.edu.cn/homebrew-bottles/api";
    HOMEBREW_BOTTLE_DOMAIN = "https://mirrors.bfsu.edu.cn/homebrew-bottles";
    # ghcr.io 格式的 bottle（如 postgresql@16）需通过 ARTIFACT_DOMAIN 镜像
    HOMEBREW_ARTIFACT_DOMAIN = "https://mirrors.bfsu.edu.cn/homebrew-bottles";
    HOMEBREW_BREW_GIT_REMOTE = "https://mirrors.bfsu.edu.cn/git/homebrew/brew.git";
    HOMEBREW_CORE_GIT_REMOTE = "https://mirrors.bfsu.edu.cn/git/homebrew/homebrew-core.git";
    HOMEBREW_PIP_INDEX_URL = "https://pypi.tuna.tsinghua.edu.cn/simple";
    # mas 安装 WeChat 需访问 itunes.apple.com，国内网络需代理
    ALL_PROXY = httpProxy;
    HTTPS_PROXY = httpProxy;
    NO_PROXY = no_proxy;
    no_proxy = no_proxy;
  };
  homebrew_env_script = lib.concatStringsSep "\n" (
    lib.attrsets.mapAttrsToList (n: v: "export ${n}=${v}") homebrew_mirror_env
  );
in
{
  # git 由 modules/base/packages.nix 提供
  environment.variables = {
    TERMINFO_DIRS = map (path: path + "/share/terminfo") config.environment.profiles ++ [
      "/usr/share/terminfo"
    ];
  };

  system.activationScripts.homebrew.text = lib.mkBefore ''
    echo >&2 '${homebrew_env_script}'
    ${homebrew_env_script}
  '';

  programs.zsh.enable = true;
  environment.shells = [ pkgs.zsh ];

  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = false; # 加速 rebuild，需要时手动 brew update
      upgrade = true;
      cleanup = "zap";
    };

    masApps = {
      "WeChat" = 836500024;
    };

    taps = [
      "nikitabobko/tap"
      "FelixKratz/formulae"
    ];

    # mas 为 masApps（如 WeChat）所需，避免被 cleanup 卸载
    # libomp 为 XGBoost/LightGBM 等 PyPI 包所需（期望 Homebrew 路径）
    # postgresql 由 Nixpkgs 提供（home/darwin/postgresql/default.nix），避免 Homebrew ghcr.io 下载失败
    brews = [ "mas" "libomp" ];

    # miniforge 体积大，256GB 建议按需 brew install
    casks = [
      "google-chrome"
      "cursor"
      "chatgpt"
      "zotero"
    ];
  };
}
