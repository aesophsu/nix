{ lib, pkgs, ... }:
{
  i18n.inputMethod.fcitx5 = {
    addons = lib.mkAfter [ pkgs.catppuccin-fcitx5 ];
    settings.addons.classicui = {
      globalSection = {
        Theme = "catppuccin-frappe-blue";
        DarkTheme = "catppuccin-frappe-blue";
        UseDarkTheme = "True";
      };
    };
  };

  fonts = {
    packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      nerd-fonts.symbols-only
    ];
    fontconfig = {
      enable = true;
      defaultFonts.monospace = [ "JetBrainsMono Nerd Font" ];
    };
  };

  programs.thunar.plugins = with pkgs; [
    thunar-archive-plugin
    thunar-volman
  ];
}
