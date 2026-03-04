{ pkgs, ... }:

{
  home.packages = [
    pkgs.git
    pkgs.git-lfs
  ];
}
