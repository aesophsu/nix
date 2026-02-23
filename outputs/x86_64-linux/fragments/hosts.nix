{
  inputs,
  lib,
  mylib,
  myvars,
  hostRegistry,
  system,
  genSpecialArgs,
  ...
}@args:
let
  hostLib = mylib.hostRegistry;
  hostsForSystem = hostLib.hostsForPlatformSystem hostRegistry "nixos" system;

  mkHostOutputs =
    host:
    let
      extraModules =
        lib.optionals (hostLib.isInstallerHost host) [
          "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
        ];

      config = lib.nixosSystem {
        inherit system;
        specialArgs = args;
        modules = extraModules ++ [ (mylib.relativeToRoot host.hostPath) ];
      };

      isoAliases = host.isoPackageAliases or [ "${host.name}-iso" ];
      isoPackages =
        if hostLib.isInstallerHost host then
          builtins.listToAttrs (
            map (alias: {
              name = alias;
              value = config.config.system.build.isoImage;
            }) isoAliases
          )
        else
          { };
    in
    {
      nixosConfigurations.${host.name} = config;
      packages = isoPackages;
    };
  fragments = map mkHostOutputs hostsForSystem;
in
{
  nixosConfigurations = hostLib.mergeField "nixosConfigurations" fragments;
  packages = hostLib.mergeField "packages" fragments;
}
