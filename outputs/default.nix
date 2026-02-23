{
  self,
  nixpkgs,
  pre-commit-hooks,
  ...
}@inputs:
let
  inherit (inputs.nixpkgs) lib;

  # =====================================================================================
  # Project-level extensions
  # =====================================================================================

  mylib = import ../lib { inherit lib; };
  myvars = import ../vars { inherit lib; };

  # OpenClaw package (exclude oracle, PATH-safe) from lib/openclaw-package.nix
  genSpecialArgs = system:
    let
      openclawPkg = import ../lib/openclaw-package.nix {
        pkgs = nixpkgs.legacyPackages.${system};
        nix-openclaw = inputs.nix-openclaw;
        nix-steipete-tools = inputs.nix-steipete-tools;
        inherit system;
      };
    in
    inputs
    // {
      inherit mylib myvars;
      openclawPackageNoOracle = openclawPkg.openclawPackageNoOracle;
    };

  # =====================================================================================
  # Common args for haumea-style module trees
  # =====================================================================================

  args = {
    inherit
      inputs
      lib
      mylib
      myvars
      genSpecialArgs
      ;
  };

  # =====================================================================================
  # System trees (per-architecture entry points)
  # =====================================================================================

  darwinSystems = {
    aarch64-darwin = import ./aarch64-darwin (args // { system = "aarch64-darwin"; });
  };
  linuxSystems = {
    x86_64-linux = import ./x86_64-linux (args // { system = "x86_64-linux"; });
  };

  darwinSystemNames = builtins.attrNames darwinSystems;
  darwinSystemValues = builtins.attrValues darwinSystems;
  linuxSystemNames = builtins.attrNames linuxSystems;
  linuxSystemValues = builtins.attrValues linuxSystems;

  # =====================================================================================
  # Helpers
  # =====================================================================================

  forDarwinSystems = func: nixpkgs.lib.genAttrs darwinSystemNames func;
  forLinuxSystems = func: nixpkgs.lib.genAttrs linuxSystemNames func;

in
{
  # =====================================================================================
  # Darwin configurations (MacBook Air M4)
  # =====================================================================================

  darwinConfigurations = lib.attrsets.mergeAttrsList (
    map (it: it.darwinConfigurations or { }) darwinSystemValues
  );
  nixosConfigurations = lib.attrsets.mergeAttrsList (
    map (it: it.nixosConfigurations or { }) linuxSystemValues
  );

  # =====================================================================================
  # Packages & evaluation
  # =====================================================================================

  packages =
    (forDarwinSystems (system: darwinSystems.${system}.packages or { }))
    // (forLinuxSystems (system: linuxSystems.${system}.packages or { }));

  # =====================================================================================
  # Checks (CI / pre-commit)
  # =====================================================================================

  checks = forDarwinSystems (system:
    let
      pkgs = nixpkgs.legacyPackages.${system};
      evalTestsEmpty = (darwinSystems.${system}.evalTests or { }) == { };
    in
    {
      eval-tests = pkgs.runCommand "eval-tests" { } ''
        ${if evalTestsEmpty then "touch $out" else "echo 'evalTests not empty' && exit 1"}
      '';

      pre-commit-check = pre-commit-hooks.lib.${system}.run {
      src = mylib.relativeToRoot ".";
      hooks = {
        nixfmt = {
          enable = true;
          settings.width = 100;
        };

        typos = {
          enable = true;
          settings = {
            write = true;
            configPath = ".typos.toml";
            exclude = "rime-data/";
          };
        };

        prettier = {
          enable = true;
          settings = {
            write = true;
            configPath = ".prettierrc.yaml";
          };
        };

        # deadnix.enable = true;
        # statix.enable = true;
      };
    };
  });

  # =====================================================================================
  # Development environments
  # =====================================================================================

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

        inherit (self.checks.${system}.pre-commit-check) shellHook;
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

  # =====================================================================================
  # Formatter
  # =====================================================================================

  formatter = forDarwinSystems (system: nixpkgs.legacyPackages.${system}.nixfmt);
}
