{
  config,
  lib,
  pkgs,
  myvars,
  ...
}:

let
  # 国内镜像：北外 Homebrew 镜像 + 清华 PyPI，部署时可不依赖 mihomo
  no_proxy = "localhost,127.0.0.1,.local,.lan,.cn,mirrors.bfsu.edu.cn,mirrors.tuna.tsinghua.edu.cn,mirrors.ustc.edu.cn,pypi.tuna.tsinghua.edu.cn,mirror.nju.edu.cn";
  homebrew_mirror_env = {
    HOMEBREW_API_DOMAIN = "https://mirrors.bfsu.edu.cn/homebrew-bottles/api";
    HOMEBREW_BOTTLE_DOMAIN = "https://mirrors.bfsu.edu.cn/homebrew-bottles";
    HOMEBREW_ARTIFACT_DOMAIN = "https://mirrors.bfsu.edu.cn/homebrew-bottles";
    HOMEBREW_BREW_GIT_REMOTE = "https://mirrors.bfsu.edu.cn/git/homebrew/brew.git";
    HOMEBREW_CORE_GIT_REMOTE = "https://mirrors.bfsu.edu.cn/git/homebrew/homebrew-core.git";
    HOMEBREW_PIP_INDEX_URL = "https://pypi.tuna.tsinghua.edu.cn/simple";
    NO_PROXY = no_proxy;
    no_proxy = no_proxy;
    # 不在激活脚本中设置 ALL_PROXY/HTTPS_PROXY，便于首轮部署时 mihomo 未就绪也能完成
    # 终端内由 home/darwin/mihomo 设置 sessionVariables，mihomo 启动后 brew 会走代理
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
