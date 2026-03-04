{ lib }:
{
  proxy = rec {
    policy = {
      # System network proxy default action on darwin activation: "on" or "off"
      systemDefault = "on";
      # Inject HTTP(S)_PROXY into user shell session by default
      cliDefault = "on";
      # Inject proxy env in homebrew activation phase
      homebrewEnv = true;
    };

    # Common macOS network services we manage via networksetup.
    systemServices = [
      "Wi-Fi"
      "Ethernet"
      "USB 10/100/1000 LAN"
      "Thunderbolt Ethernet"
    ];

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
}
