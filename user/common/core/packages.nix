{ pkgs, ... }:

{
  # Base user-level CLI packages (toolchain/vcs/infra are split into tooling/*).
  home.packages = [
    pkgs.nix-index
    pkgs.nix-tree
    pkgs.gnupg
    pkgs.codex
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
