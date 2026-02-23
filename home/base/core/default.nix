{ mylib, ... }:

let
  groupedDirs = [
    ./shells
  ];
  topLevelModules = builtins.filter (path: !(builtins.elem path groupedDirs)) (mylib.scanPaths ./.);
in
{
  imports = topLevelModules ++ groupedDirs;
}
