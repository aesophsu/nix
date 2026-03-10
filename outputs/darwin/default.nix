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
    darwin-modules = map mylib.relativeToRoot [ "profiles/system/stella.nix" ];

    home-modules = map mylib.relativeToRoot [ "profiles/user/stella.nix" ];
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
