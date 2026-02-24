{ lib, nixpkgs, smokeCheckLib, pre-commit-hooks, preCommitHooks, mylib }:
{
  allSystems,
  allSystemNames,
  docInventory,
}:
lib.genAttrs allSystemNames (
  system:
  let
    pkgs = nixpkgs.legacyPackages.${system};
    tests = allSystems.${system}.evalTests or { };
    docInventoryJson = pkgs.writeText "doc-inventory.json" (builtins.toJSON docInventory);
  in
  {
    smoke-eval = smokeCheckLib.mkSmokeCheck pkgs tests;
    docs-sync = pkgs.runCommand "docs-sync" { } ''
      cd ${mylib.relativeToRoot "."}
      ${pkgs.python3}/bin/python ./scripts/docs/generate.py --check --inventory-file ${docInventoryJson}
      touch $out
    '';
  }
  // lib.optionalAttrs (builtins.hasAttr system pre-commit-hooks.lib) {
    pre-commit = pre-commit-hooks.lib.${system}.run {
      src = mylib.relativeToRoot ".";
      hooks = preCommitHooks;
    };
  }
)
