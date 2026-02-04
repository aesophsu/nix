{ lib }:
rec {
  # mihomo 代理端口（与 home/darwin/mihomo/config.yaml 或 config.local.yaml 一致）
  mihomo = {
    host = "127.0.0.1";
    httpPort = "7890";
    socksPort = "7891";
    mixedPort = "7893"; # HTTP+SOCKS 混合端口
    httpProxy = "http://127.0.0.1:7890";
    socksProxy = "socks5://127.0.0.1:7891";
  };

  # 国内 DNS，加速域名解析
  nameservers = [
    "119.29.29.29" # DNSPod
    "223.5.5.5" # AliDNS
  ];

  # 主机网络配置（当前仅 stella）
  hostsAddr = {
    stella = {
      iface = "en0";
      ipv4 = "10.0.0.3"; # 记录用，实际由 DHCP 分配
    };
  };

  # 接口配置：使用 DHCP 获取 IP
  hostsInterface = lib.attrsets.mapAttrs (_: val: {
    interfaces."${val.iface}" = {
      useDHCP = true;
      ipv4.addresses = [ ];
    };
  }) hostsAddr;

  ssh = {
    extraConfig = "";

    # GitHub 主机密钥，SSH 连接时免交互确认
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
