{
  pkgs,
  config,
  lib,
  ...
}:

let
  cfg = config.modules.desktop;
in
{
  # =====================================================================================
  # Options
  # =====================================================================================

  options.modules.desktop = {
    fonts.enable = lib.mkEnableOption "Enable rich desktop fonts";
  };

  # =====================================================================================
  # Font packages
  # =====================================================================================

  # Slim font set: icons, monospace, CJK essentials
  config.fonts.packages = lib.mkIf cfg.fonts.enable (
    with pkgs;
    [
      material-design-icons
      nerd-fonts.symbols-only
      nerd-fonts.fira-code
      noto-fonts
      noto-fonts-color-emoji
      source-han-sans
      lxgw-wenkai-screen
    ]
  );
}
