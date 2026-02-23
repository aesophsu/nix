{ ... }:
{
  networking.networkmanager = {
    enable = true;
    wifi.backend = "iwd";
  };
  networking.wireless.enable = false;
  security.polkit.enable = true;
}
