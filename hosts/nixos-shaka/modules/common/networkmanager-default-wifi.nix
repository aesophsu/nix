{ ... }:
{
  # Declarative default Wi-Fi profile for Shaka and the installer.
  # NOTE: The PSK is stored in the Nix store in plaintext because this host is configured as a self-contained installer.
  networking.networkmanager.ensureProfiles.profiles.pi-default = {
    connection = {
      id = "Pi";
      type = "wifi";
      autoconnect = true;
      autoconnect-priority = 100;
      permissions = "";
    };
    wifi = {
      mode = "infrastructure";
      ssid = "Pi";
    };
    wifi-security = {
      auth-alg = "open";
      key-mgmt = "wpa-psk";
      psk = "zxcvbnm8";
    };
    ipv4 = {
      method = "auto";
      dns-search = "";
    };
    ipv6 = {
      method = "auto";
      addr-gen-mode = "stable-privacy";
      dns-search = "";
    };
  };
}
