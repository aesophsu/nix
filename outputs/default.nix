{
  self,
  nixpkgs,
  pre-commit-hooks,
  ...
}@inputs:
let
  inherit (inputs.nixpkgs) lib;

  # Top-level flake outputs aggregator: shared helpers + per-system trees.
  mylib = import ../lib { inherit lib; };
  myvars = import ../vars { inherit lib; };
  hostRegistryLib = mylib.hostRegistry;
  hostRegistryRaw = import ../hosts/registry.nix { inherit myvars; };
  hostRegistry = hostRegistryLib.indexRegistry hostRegistryRaw;
  smokeCheckLib = import ./lib/smoke-check.nix { inherit lib; };
  preCommitHooks = import ./lib/pre-commit-hooks.nix;

  # Shared arguments injected into system builders/modules via specialArgs.
  genSpecialArgs = system:
    inputs
    // {
      inherit system mylib myvars hostRegistry;
    };

  # Common args for per-system output trees.
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

  # Per-system output entry points.
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
  allSystemValues = builtins.attrValues allSystems;

  # =====================================================================================
  # Helpers
  # =====================================================================================

  forDarwinSystems = func: nixpkgs.lib.genAttrs darwinSystemNames func;
  forNixosSystems = func: nixpkgs.lib.genAttrs nixosSystemNames func;
  forAllSystems = func: nixpkgs.lib.genAttrs allSystemNames func;
  checkNamesForSystem =
    system:
    [
      "smoke-eval"
      "docs-sync"
    ]
    ++ lib.optionals (builtins.hasAttr system pre-commit-hooks.lib) [ "pre-commit" ];
  docInventory = {
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
  };

in
{
  # Aggregated system configurations.
  darwinConfigurations = lib.attrsets.mergeAttrsList (
    map (it: it.darwinConfigurations or { }) darwinSystemValues
  );
  nixosConfigurations = lib.attrsets.mergeAttrsList (
    map (it: it.nixosConfigurations or { }) nixosSystemValues
  );

  packages =
    (forDarwinSystems (system: darwinSystems.${system}.packages or { }))
    // (forNixosSystems (system: nixosSystems.${system}.packages or { }));

  # Unified checks: smoke-eval plus pre-commit where supported on the target system.
  checks = forAllSystems (system:
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
  );

  devShells = forDarwinSystems (
    system:
    let
      pkgs = nixpkgs.legacyPackages.${system};
      pythonWithTools = pkgs.python312.withPackages (ps:
        with ps; [
          pip
          ipython
          numpy
          pandas
          matplotlib
          requests
        ]);
    in
    {
      default = pkgs.mkShell {
        name = "dots";

        packages = with pkgs; [
          bashInteractive
          gcc

          nodejs_20
          pnpm

          nixfmt
          deadnix
          statix

          typos
          nodePackages.prettier
        ];

        inherit (self.checks.${system}.pre-commit) shellHook;
      };

      # Python project dev shell
      python = pkgs.mkShell {
        name = "python";

        packages = with pkgs; [
          pythonWithTools
          ruff
          uv
        ];

        shellHook = ''
          echo "Python: $(python --version)"
          echo "uv: $(uv --version 2>/dev/null || true)"
          echo ""
          echo "Project venv example:"
          echo "  uv venv && source .venv/bin/activate"
          echo "  uv pip install -r requirements.txt"
        '';
      };
    }
  );

  formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt);

  inherit docInventory;
}
