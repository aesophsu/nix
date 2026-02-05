{
  config,
  lib,
  pkgs,
  myvars,
  ...
}:

let
  # Mirrors: Homebrew (BFSU) + PyPI (Tsinghua); deploy without proxy
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
    # No ALL_PROXY in activation so first deploy works without mihomo; shell gets proxy from mihomo HM module
  };
  homebrew_env_script = lib.concatStringsSep "\n" (
    lib.attrsets.mapAttrsToList (n: v: "export ${n}=${v}") homebrew_mirror_env
  );
in
{
  # git from modules/base/packages.nix
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
      autoUpdate = false; # faster rebuild; run brew update when needed
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

    # mas for masApps (e.g. WeChat); libomp for XGBoost/LightGBM; postgresql from Nix (home/darwin/postgresql)
    brews = [ "mas" "libomp" ];

    # miniforge is large; brew install on demand if needed
    casks = [
      "google-chrome"
      "cursor"
      "chatgpt"
      "zotero"
    ];
  };
}
