{ lib }:
{
  proxy = rec {
    policy = {
      # Manual system proxy preference for operator-facing tooling.
      # `darwin-rebuild switch` must not mutate current network proxy state.
      systemDefault = "off";
      # Manual shell proxy preference. Proxy env is exported only via explicit commands.
      cliDefault = "off";
      # Homebrew activation should not inject proxy env during rebuilds.
      homebrewEnv = false;
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
