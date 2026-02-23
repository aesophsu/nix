{ ... }:
{
  imports = [
    ./modules/base.nix
    ./modules/auto-install.nix
  ];

  system.stateVersion = "24.11";
}
