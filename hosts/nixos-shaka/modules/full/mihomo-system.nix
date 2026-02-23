{ lib, pkgs, shaka, ... }:
{
  networking.firewall.allowedTCPPorts = [
    (lib.toInt shaka.mihomo.vars.httpPort)
    (lib.toInt shaka.mihomo.vars.socksPort)
    (lib.toInt shaka.mihomo.vars.mixedPort)
    9090
  ];
  networking.firewall.checkReversePath = "loose";

  services.mihomo = {
    enable = true;
    configFile = shaka.mihomo.configSource;
    webui = pkgs.metacubexd;
    tunMode = true;
  };
  systemd.services.mihomo.serviceConfig = {
    Restart = lib.mkForce "always";
    RestartSec = "3s";
  };

  environment.variables = {
    http_proxy = shaka.mihomo.vars.httpProxy;
    https_proxy = shaka.mihomo.vars.httpProxy;
    all_proxy = shaka.mihomo.vars.socksProxy;
    HTTP_PROXY = shaka.mihomo.vars.httpProxy;
    HTTPS_PROXY = shaka.mihomo.vars.httpProxy;
    ALL_PROXY = shaka.mihomo.vars.socksProxy;
    no_proxy = shaka.mihomo.noProxy;
    NO_PROXY = shaka.mihomo.noProxy;
  };

  environment.etc = {
    "shaka/mihomo/config.yaml.example".source = ../../../../home/darwin/services/mihomo/config.yaml.example;
    "shaka/mihomo/README.md".text = ''
      Mihomo (system service) config path priority on Shaka:

      1. /etc/nixos/local/mihomo/config.yaml    (recommended, not in git / not in nix store)
      2. hosts/nixos-shaka/mihomo.config.local.yaml
      3. hosts/nixos-shaka/mihomo.config.yaml
      4. bundled example template

      Recommended workflow (clash.meta / mihomo style):
      - Copy /etc/shaka/mihomo/config.yaml.example -> /etc/nixos/local/mihomo/config.yaml
      - Fill in subscription token URLs
      - Keep TUN enabled in config for global proxy
      - Restart: sudo systemctl restart mihomo

      Dashboard:
      - http://127.0.0.1:9090/ui   (MetaCubeXD local webui)
    '';
    "shaka/mihomo/subscriptions.example.yaml".text = ''
      # Placeholder only (not consumed automatically).
      # Keep your subscription URLs/tokens here for reference, then merge them into config.yaml.
      subscriptions:
        airport1: "https://example.com/sub?token=REPLACE_ME"
        airport2: "https://example.org/sub?token=REPLACE_ME"
    '';
  };

  system.activationScripts.shaka-local-mihomo-placeholders.text = ''
    set -eu
    cp_bin="${pkgs.coreutils}/bin/cp"
    mkdir_bin="${pkgs.coreutils}/bin/mkdir"

    $mkdir_bin -p /etc/nixos/local/mihomo
    if [ ! -e /etc/nixos/local/mihomo/README.md ]; then
      $cp_bin /etc/shaka/mihomo/README.md /etc/nixos/local/mihomo/README.md
    fi
    if [ ! -e /etc/nixos/local/mihomo/config.yaml.example ]; then
      $cp_bin /etc/shaka/mihomo/config.yaml.example /etc/nixos/local/mihomo/config.yaml.example
    fi
    if [ ! -e /etc/nixos/local/mihomo/subscriptions.example.yaml ]; then
      $cp_bin /etc/shaka/mihomo/subscriptions.example.yaml /etc/nixos/local/mihomo/subscriptions.example.yaml
    fi
  '';

  environment.systemPackages = with pkgs; [
    mihomo
    fwupd
  ];
}
