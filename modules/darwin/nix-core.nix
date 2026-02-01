{ config, ... }:

{
  # Determinate Nix 使用自有 daemon，需关闭 nix-darwin 的 Nix 管理
  nix = {
    enable = false;
    settings.auto-optimise-store = false;
    extraOptions = "";
    gc.automatic = false;
  };

  system.stateVersion = 5;
}
