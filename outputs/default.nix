{
  self,
  nixpkgs,
  pre-commit-hooks,
  ...
}@inputs:
let
  inherit (inputs.nixpkgs) lib;

  mylib = import ../lib { inherit lib; };
  myvars = import ../vars { inherit lib; };
  hostRegistryLib = mylib.hostRegistry;
  hostRegistryRaw = import ../hosts/registry.nix { inherit myvars; };
  hostRegistry = hostRegistryLib.indexRegistry hostRegistryRaw;
  smokeCheckLib = import ./lib/smoke-check.nix { inherit lib; };
  preCommitHooks = import ./lib/pre-commit-hooks.nix;

  genSpecialArgs = system:
    inputs
    // {
      inherit inputs system mylib myvars hostRegistry;
    };

  args = {
    inherit
      inputs
      lib
      mylib
      myvars
      hostRegistry
      hostRegistryRaw
      genSpecialArgs
      ;
  };

  darwinSystems = {
    aarch64-darwin = import ./aarch64-darwin (args // { system = "aarch64-darwin"; });
  };
  nixosSystems = {
    x86_64-linux = import ./x86_64-linux (args // { system = "x86_64-linux"; });
  };
  allSystems = nixosSystems // darwinSystems;

  darwinSystemNames = builtins.attrNames darwinSystems;
  darwinSystemValues = builtins.attrValues darwinSystems;
  nixosSystemNames = builtins.attrNames nixosSystems;
  nixosSystemValues = builtins.attrValues nixosSystems;
  allSystemNames = builtins.attrNames allSystems;

  forDarwinSystems = func: nixpkgs.lib.genAttrs darwinSystemNames func;
  forNixosSystems = func: nixpkgs.lib.genAttrs nixosSystemNames func;
  forAllSystems = func: nixpkgs.lib.genAttrs allSystemNames func;

  mkDocInventory = import ./doc-inventory.nix { inherit lib pre-commit-hooks; };
  mkChecks = import ./checks.nix {
    inherit lib nixpkgs smokeCheckLib pre-commit-hooks preCommitHooks mylib;
  };
  mkDevShells = import ./devshells.nix { inherit self lib nixpkgs; };

  docInventory = mkDocInventory {
    inherit hostRegistry darwinSystemNames nixosSystemNames allSystemNames;
  };
in
{
  darwinConfigurations = lib.attrsets.mergeAttrsList (
    map (it: it.darwinConfigurations or { }) darwinSystemValues
  );
  nixosConfigurations = lib.attrsets.mergeAttrsList (
    map (it: it.nixosConfigurations or { }) nixosSystemValues
  );

  packages =
    (forDarwinSystems (system: darwinSystems.${system}.packages or { }))
    // (forNixosSystems (system: nixosSystems.${system}.packages or { }));

  checks = mkChecks {
    inherit allSystems allSystemNames docInventory;
  };

  devShells = mkDevShells { inherit darwinSystemNames; };

  formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt);

  inherit docInventory;
}
