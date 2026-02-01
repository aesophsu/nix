{
  config,
  lib,
  pkgs,
  ...
}:

let
  homebrew_mirror_env = {
    HOMEBREW_API_DOMAIN = "https://mirrors.bfsu.edu.cn/homebrew-bottles/api";
    HOMEBREW_BOTTLE_DOMAIN = "https://mirrors.bfsu.edu.cn/homebrew-bottles";
    HOMEBREW_BREW_GIT_REMOTE = "https://mirrors.bfsu.edu.cn/git/homebrew/brew.git";
    HOMEBREW_CORE_GIT_REMOTE = "https://mirrors.bfsu.edu.cn/git/homebrew/homebrew-core.git";
    HOMEBREW_PIP_INDEX_URL = "https://pypi.tuna.tsinghua.edu.cn/simple";
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
    brews = [ "mas" ];

    # miniforge 体积大，256GB 建议按需 brew install
    casks = [
      "google-chrome"
      "cursor"
    ];
  };
}
