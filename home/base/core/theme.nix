{ catppuccin, ... }:
{
  imports = [
    catppuccin.homeModules.catppuccin
  ];

  catppuccin = {
    enable = true;
    flavor = "mocha"; # Select theme flavor
    accent = "pink"; # Set accent color for the theme
  };
}
