{ ... }:
{
  imports = [
    ../modules/base.nix
    ../modules/hardware-mbp112.nix
    ../modules/install-helper.nix
    ../modules/ui-tty.nix
  ];

  system.stateVersion = "24.11";
}
