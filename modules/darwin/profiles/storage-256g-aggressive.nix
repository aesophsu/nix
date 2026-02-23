{ lib, ... }:

{
  # More aggressive disk strategy for 256G Macs:
  # - Move large GUI apps to Homebrew casks (outside Nix store generations)
  # - Let nix-darwin clean Homebrew stale downloads/old versions during activation
  homebrew = {
    casks = [
      "codex-app"
      "cursor"
      "google-chrome"
      "telegram"
      "zotero"
    ];

    onActivation.cleanup = lib.mkForce "zap";
  };
}
