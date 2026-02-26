{ pkgs, ... }:

{
  # 256G SSD 优化：重量级 GUI 应用改由 Homebrew cask 管理（见 system/darwin/profiles/storage-256g-aggressive.nix）
  # 避免 Nix store 因代际累积占用过多空间。
  home.packages = with pkgs; [
  ];
}
