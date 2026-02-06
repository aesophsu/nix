{ pkgs, ... }:

{
  # macOS GUI 应用，改由 Home Manager 通过 Nix 管理
  home.packages = with pkgs; [
    code-cursor
    google-chrome
    telegram-desktop
    zotero
  ];
}

