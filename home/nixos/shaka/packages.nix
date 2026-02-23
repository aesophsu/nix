{ pkgs, ... }:
{
  home.packages = with pkgs; [
    kitty
    waybar
    fuzzel
    swaylock
    brightnessctl
    playerctl
    pavucontrol
    curl
    wget
    git
    evince
    networkmanagerapplet
    google-chrome
    codex
    zotero
    wechat-uos
    vscode
    telegram-desktop
    catppuccin-gtk
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    TERMINAL = "kitty";
    BROWSER = "google-chrome-stable";
    NIXOS_OZONE_WL = "1";
    GTK_THEME = "catppuccin-frappe-blue-standard";
  };
}
