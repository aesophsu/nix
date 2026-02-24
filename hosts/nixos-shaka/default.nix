{ lib, pkgs, mylib, myvars ? null, ... }:
let
  username = if myvars != null then myvars.username else "sue";
  mihomoVars =
    if myvars != null && myvars ? networking && myvars.networking ? mihomo then
      myvars.networking.mihomo
    else
      {
        host = "127.0.0.1";
        httpPort = "7890";
        socksPort = "7891";
        mixedPort = "7893";
        httpProxy = "http://127.0.0.1:7890";
        socksProxy = "socks5://127.0.0.1:7891";
      };
  mihomoLocalConfigPath = /etc/nixos/local/mihomo/config.yaml;
  mihomoConfigSource = mylib.firstExistingPathOr {
    candidates = [
      mihomoLocalConfigPath
      ./mihomo.config.local.yaml
      ./mihomo.config.yaml
    ];
    default = ../../home/darwin/services/mihomo/config.yaml.example;
  };
  mihomoNoProxy =
    if myvars != null && myvars ? networking && myvars.networking ? proxy then
      myvars.networking.proxy.mkNoProxy {
        extra = [
          "10.0.0.0/8"
          "172.16.0.0/12"
          "192.168.0.0/16"
        ];
      }
    else
      "localhost,127.0.0.1,::1,.local,.lan,.cn,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16";

in
{
  imports = [
    ./modules/common/base-system.nix
    ./modules/common/storage-btrfs-hibernate.nix
    ./modules/hardware/macbookpro11-2-igpu.nix
    ./modules/common/platform-hardware.nix
    ./modules/common/network-core.nix
    ./modules/common/network-mbp11-2-stability.nix
    ./modules/common/networkmanager-default-wifi.nix
    ./modules/common/power-and-runtime.nix
    ./modules/common/gui-core.nix
    ./modules/common/user-login-core.nix
    ./modules/full/home-manager.nix
    ./modules/full/profile.nix
  ];

  _module.args.shaka = {
    inherit username;
    mihomo = {
      vars = mihomoVars;
      noProxy = mihomoNoProxy;
      configSource = mihomoConfigSource;
    };
  };
}
