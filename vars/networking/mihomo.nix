{
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
}
