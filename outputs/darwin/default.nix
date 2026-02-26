{
  inputs,
  lib,
  mylib,
  myvars,
  system,
  genSpecialArgs,
  ...
}@args:
let
  stellaModules = {
    darwin-modules =
      (map mylib.relativeToRoot [
        "system/common"
        "system/darwin"
        "hosts/stella/system.nix"
      ])
      ++ [
        {
          modules.desktop.fonts.enable = true;
        }
      ];

    home-modules = map mylib.relativeToRoot [
      "hosts/stella/home.nix"
      "user/darwin"
    ];
  };

  stellaConfig = mylib.macosSystem (args // stellaModules);

  outputs = {
    darwinConfigurations.stella = stellaConfig;
  };
in
outputs
// {
  evalTests = import ./tests (args // { configurations = outputs.darwinConfigurations; });
}
