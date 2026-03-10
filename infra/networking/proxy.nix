{ lib }:
{
  proxy = rec {
    policy = {
      systemDefault = "off";
      cliDefault = "on";
      homebrewEnv = false;
    };

    systemServices = [
      "Wi-Fi"
      "Ethernet"
      "USB 10/100/1000 LAN"
      "Thunderbolt Ethernet"
    ];

    noProxyLocal = [
      "localhost"
      "127.0.0.1"
      "*.local"
      "169.254/16"
    ];

    noProxyBaseDomains = [ ];

    mkNoProxyList =
      {
        extra ? [ ],
      }:
      noProxyLocal ++ noProxyBaseDomains ++ extra;
    mkNoProxy =
      {
        extra ? [ ],
      }:
      lib.concatStringsSep "," (mkNoProxyList {
        inherit extra;
      });

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
}
