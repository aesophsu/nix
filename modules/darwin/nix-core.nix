{ config, ... }:

{
  # Determinate Nix uses its own daemon; disable nix-darwin Nix management
  nix = {
    enable = false;
    settings.auto-optimise-store = false;
    extraOptions = "";
    gc.automatic = false;
  };

  system.stateVersion = 5;
}
