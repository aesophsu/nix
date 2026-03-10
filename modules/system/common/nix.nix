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
    accept-flake-config = true;

    # Keep builds responsive without over-tuning per host.
    max-jobs = "auto";
    cores = 0;

    # Prefer substituter mirrors so first deploy can run without proxy
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
    fallback = false; # fail fast if no binary cache; avoid surprise source builds on 256G SSD

    # 256G SSD: favor reclaimable store metadata and keep headroom before builds.
    keep-outputs = false;
    keep-derivations = false;
    min-free = 5 * 1024 * 1024 * 1024; # 5 GiB
    max-free = 15 * 1024 * 1024 * 1024; # 15 GiB

    # Disable Rosetta build to save store space
    # extra-platforms = [ "x86_64-darwin" ];
  };
}
