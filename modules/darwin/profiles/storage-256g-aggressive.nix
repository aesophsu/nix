{ lib, ... }:

{
  # More aggressive disk strategy for 256G Macs:
  # - Move large GUI apps to Homebrew casks (outside Nix store generations)
  # - Let nix-darwin clean Homebrew stale downloads/old versions during activation
  homebrew = {
    # Manage selected heavy GUI apps with Homebrew casks (outside Nix store).
    casks = [
      "cursor"
      "chatgpt"
      "google-chrome"
      "telegram"
    ];

    # Avoid mass-uninstalling Homebrew apps during rebuilds.
    onActivation.cleanup = lib.mkForce "none";
  };
}
