{ pkgs, ... }:

{
  environment.variables.EDITOR = "nvim --clean";
  environment.systemPackages = with pkgs; [
    git
    git-lfs
    openssl
  ];
}
