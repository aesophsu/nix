{ pkgs, ... }:

{
  home.packages = [
    pkgs.docker
    pkgs.docker-compose
    pkgs.jq
    pkgs.curl
  ];
}
