{
  pkgs,
  config,
  myvars,
  ...
}:
{
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];

    trusted-users = [ myvars.username ];

    # 国内：优先使用国内 substituter，无需代理即可拉包；首轮部署可不依赖 mihomo
    substituters = [
      "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
      "https://mirrors.ustc.edu.cn/nix-channels/store"
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
    ];

    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];

    builders-use-substitutes = true;

    # 256GB 不启用 Rosetta 构建，节省 store 空间
    # extra-platforms = [ "x86_64-darwin" ];
  };
}
