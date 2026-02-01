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

  # 256GB 精简字体：图标、等宽、CJK essentials
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
