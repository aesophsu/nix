{
  nixpkgs,
  pre-commit-hooks,
  ...
}@inputs:
let
  system = "aarch64-darwin";
  inherit (inputs.nixpkgs) lib;

  mylib = import ../lib { inherit lib; };
  myvars = import ../vars { inherit lib; };
  smokeCheckLib = import ./lib/smoke-check.nix { inherit lib; };
  preCommitHooks = import ./lib/pre-commit-hooks.nix;

  genSpecialArgs =
    targetSystem:
    inputs
    // {
      system = targetSystem;
      inherit mylib myvars;
    };

  args = {
    inherit
      inputs
      lib
      mylib
      myvars
      genSpecialArgs
      ;
    inherit system;
  };

  darwinOutputs = import ./darwin args;

  pkgs = nixpkgs.legacyPackages.${system};
  tests = darwinOutputs.evalTests or { };
in
{
  darwinConfigurations = darwinOutputs.darwinConfigurations or { };

  packages = {
    "aarch64-darwin" = darwinOutputs.packages or { };
  };

  checks = {
    "aarch64-darwin" =
      {
        smoke-eval = smokeCheckLib.mkSmokeCheck pkgs tests;
      }
      // lib.optionalAttrs (builtins.hasAttr system pre-commit-hooks.lib) {
        pre-commit = pre-commit-hooks.lib.${system}.run {
          src = mylib.relativeToRoot ".";
          hooks = preCommitHooks;
        };
      };
  };

  formatter = {
    "aarch64-darwin" = pkgs.nixfmt;
  };
}
