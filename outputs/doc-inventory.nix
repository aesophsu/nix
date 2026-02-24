{ lib, pre-commit-hooks }:
{
  hostRegistry,
  darwinSystemNames,
  nixosSystemNames,
  allSystemNames,
}:
let
  checkNamesForSystem =
    system:
    [
      "smoke-eval"
      "docs-sync"
    ]
    ++ lib.optionals (builtins.hasAttr system pre-commit-hooks.lib) [ "pre-commit" ];
in
{
  hosts = hostRegistry.hosts;
  enabledHosts = hostRegistry.enabledHosts;
  systems = {
    darwin = darwinSystemNames;
    nixos = nixosSystemNames;
    all = allSystemNames;
  };
  outputs = {
    topLevel = [
      "darwinConfigurations"
      "nixosConfigurations"
      "packages"
      "checks"
      "devShells"
      "formatter"
      "docInventory"
    ];
    platformFragments = {
      "aarch64-darwin" = "outputs/aarch64-darwin/fragments";
      "x86_64-linux" = "outputs/x86_64-linux/fragments";
    };
  };
  checks = builtins.listToAttrs (
    map (system: {
      name = system;
      value = checkNamesForSystem system;
    }) allSystemNames
  );
}
