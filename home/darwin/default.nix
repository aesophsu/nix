{ mylib, myvars, ... }:

let
  groupedDirs = [
    ./apps
    ./services
    ./profiles
  ];
  topLevelModules = builtins.filter (path: !(builtins.elem path groupedDirs)) (mylib.scanPaths ./.);
in
{
  home.homeDirectory = "/Users/${myvars.username}";
  xdg.enable = true;

  imports = topLevelModules ++ groupedDirs ++ [
    ../base/core
    ../base/home.nix
  ];
}
