# DNS, proxy, no_proxy for mirror domains (mainland-friendly)

{ lib }:
rec {
  proxy = rec {
    noProxyLocal = [
      "localhost"
      "127.0.0.1"
      "::1"
      ".local"
      ".lan"
    ];

    noProxyBaseDomains = [
      ".cn"
      "mirror.nju.edu.cn"
      "pypi.tuna.tsinghua.edu.cn"
      "mirrors.ustc.edu.cn"
      "mirrors.bfsu.edu.cn"
      "mirrors.tuna.tsinghua.edu.cn"
    ];

    mkNoProxyList = { extra ? [ ] }: noProxyLocal ++ noProxyBaseDomains ++ extra;
    mkNoProxy = { extra ? [ ] }: lib.concatStringsSep "," (mkNoProxyList { inherit extra; });

    env =
      {
        httpProxy,
        socksProxy,
        noProxyList ? mkNoProxyList { },
      }:
      let
        noProxy = lib.concatStringsSep "," noProxyList;
      in
      {
        http_proxy = httpProxy;
        https_proxy = httpProxy;
        all_proxy = socksProxy;
        HTTP_PROXY = httpProxy;
        HTTPS_PROXY = httpProxy;
        ALL_PROXY = socksProxy;
        no_proxy = noProxy;
        NO_PROXY = noProxy;
      };
  };

  mihomo = rec {
    # mihomo ports (match user/darwin/services/mihomo config). Rebuild first, then configure/start mihomo.
    host = "127.0.0.1";
    ports = {
      http = "7890";
      socks = "7891";
      mixed = "7893"; # HTTP+SOCKS mixed port
    };
    httpPort = ports.http;
    socksPort = ports.socks;
    mixedPort = ports.mixed;
    proxies = {
      http = "http://${host}:${httpPort}";
      socks = "socks5://${host}:${socksPort}";
    };
    httpProxy = proxies.http;
    socksProxy = proxies.socks;
    geodata = {
      baseUrl = "https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@release";
      managedFiles = [
        "country.mmdb"
        "GeoLite2-ASN.mmdb"
        "geosite.dat"
        "geoip.dat"
        "geoip.metadb"
      ];
      mirrorDir = "/Users/sue/Code/nix/user/darwin/services/mihomo/.runtime";
      onFailure = "fallback-continue";
    };
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
