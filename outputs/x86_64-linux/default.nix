{
  inputs,
  lib,
  mylib,
  system,
  ...
}@args:
let
  installerHostName = "shaka-installer";
  installedHostName = "shaka";

  installerConfig = lib.nixosSystem {
    inherit system;
    specialArgs = args;
    modules = [
      "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
      (mylib.relativeToRoot "hosts/nixos-${installerHostName}")
    ];
  };

  installedConfig = lib.nixosSystem {
    inherit system;
    specialArgs = args;
    modules = [
      (mylib.relativeToRoot "hosts/nixos-${installedHostName}")
    ];
  };

in
{
  nixosConfigurations.${installerHostName} = installerConfig;
  nixosConfigurations.${installedHostName} = installedConfig;

  packages = {
    macbookpro11-2-installer-iso = installerConfig.config.system.build.isoImage;
    shaka-installer-iso = installerConfig.config.system.build.isoImage;
  };

  evalTests = { };
}
