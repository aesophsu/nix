{ pkgs, ... }:

{
  # Base user-level stable CLI packages.
  # Rolling user tools such as codex CLI are installed outside Nix on purpose.
  home.packages = [
    pkgs.nix-index
    pkgs.nix-tree
    pkgs.gnupg
    pkgs.ollama
    pkgs.tree
    pkgs.wget
    pkgs.go
  ];

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
