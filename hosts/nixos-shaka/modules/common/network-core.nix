{ ... }:
{
  networking.networkmanager = {
    enable = true;
  };
#  networking.wireless.enable = false;
  security.polkit.enable = true;
}
