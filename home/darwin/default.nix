{ mylib, myvars, ... }:

{
  home.homeDirectory = "/Users/${myvars.username}";
  xdg.enable = true;

  imports = (mylib.scanPaths ./.) ++ [
    ../base/core
    ../base/home.nix
  ];
}
