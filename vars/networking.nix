# DNS, proxy, no_proxy for mirror domains (mainland-friendly)

{ lib }:
rec {
  # mihomo ports (match home/darwin/mihomo config). Rebuild first, then configure/start mihomo.
  mihomo = {
    host = "127.0.0.1";
    httpPort = "7890";
    socksPort = "7891";
    mixedPort = "7893"; # HTTP+SOCKS mixed port
    httpProxy = "http://127.0.0.1:7890";
    socksProxy = "socks5://127.0.0.1:7891";
  };

  # DNS for faster resolution; alternatives: 114.114.114.114, 180.76.76.76
  nameservers = [
    "119.29.29.29" # DNSPod
    "223.5.5.5"    # AliDNS
  ];

  # Host networking (currently stella only)
  hostsAddr = {
    stella = {
      iface = "en0";
      ipv4 = "10.0.0.3"; # for reference; actual IP via DHCP
    };
  };

  # Interface: DHCP for IP
  hostsInterface = lib.attrsets.mapAttrs (_: val: {
    interfaces."${val.iface}" = {
      useDHCP = true;
      ipv4.addresses = [ ];
    };
  }) hostsAddr;

  ssh = {
    extraConfig = "";

    # GitHub host key for non-interactive SSH
    knownHosts = {
      "github.com" = {
        hostNames = [
          "github.com"
          "140.82.113.3"
        ];
        publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";
      };
    };
  };
}
