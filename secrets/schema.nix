{
  darwinStella = {
    mihomoConfig = "darwin/stella/mihomo-config.yaml.age";
  };

  nixosShaka = {
    mihomoConfig = "nixos/shaka/mihomo-config.yaml.age";
  };

  byProfile = {
    darwin-stella = {
      home-manager = {
        mihomoConfig = "darwin/stella/mihomo-config.yaml.age";
      };
    };

    nixos-shaka = {
      nixos = {
        mihomoConfig = "nixos/shaka/mihomo-config.yaml.age";
      };
    };
  };
}
