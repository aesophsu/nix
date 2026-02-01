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

  genSpecialArgs = system: inputs // { inherit mylib myvars; };

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

  # NixOS：需存在 outputs/<arch>/ 目录
  nixosSystems = {
    # x86_64-linux  = import ./x86_64-linux  (args // { system = "x86_64-linux"; });
    # aarch64-linux = import ./aarch64-linux (args // { system = "aarch64-linux"; });
  };

  darwinSystems = {
    aarch64-darwin = import ./aarch64-darwin (args // { system = "aarch64-darwin"; });
  };

  allSystems = nixosSystems // darwinSystems;
  allSystemNames = builtins.attrNames allSystems;
  nixosSystemValues = builtins.attrValues nixosSystems;
  darwinSystemValues = builtins.attrValues darwinSystems;
  allSystemValues = nixosSystemValues ++ darwinSystemValues;

  # =====================================================================================
  # Helpers
  # =====================================================================================

  forAllSystems = func: nixpkgs.lib.genAttrs allSystemNames func;

in
{
  # =====================================================================================
  # NixOS & Darwin configurations
  # =====================================================================================

  nixosConfigurations = lib.attrsets.mergeAttrsList (
    map (it: it.nixosConfigurations or { }) nixosSystemValues
  );

  darwinConfigurations = lib.attrsets.mergeAttrsList (
    map (it: it.darwinConfigurations or { }) darwinSystemValues
  );

  # =====================================================================================
  # Colmena (remote deployment)
  # =====================================================================================

  colmena = {
    meta =
      let
        system = "x86_64-linux";
      in
      {
        nixpkgs = import nixpkgs { inherit system; };
        specialArgs = genSpecialArgs system;
      };

    nodeNixpkgs = lib.attrsets.mergeAttrsList (
      map (it: it.colmenaMeta.nodeNixpkgs or { }) nixosSystemValues
    );

    nodeSpecialArgs = lib.attrsets.mergeAttrsList (
      map (it: it.colmenaMeta.nodeSpecialArgs or { }) nixosSystemValues
    );
  }
  // lib.attrsets.mergeAttrsList (map (it: it.colmena or { }) nixosSystemValues);

  # =====================================================================================
  # Packages & evaluation
  # =====================================================================================

  packages = forAllSystems (system: allSystems.${system}.packages or { });

  # =====================================================================================
  # Checks (CI / pre-commit)
  # =====================================================================================

  checks = forAllSystems (system:
    let
      pkgs = nixpkgs.legacyPackages.${system};
      evalTestsEmpty = allSystems.${system}.evalTests == { };
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

  devShells = forAllSystems (
    system:
    let
      pkgs = nixpkgs.legacyPackages.${system};
      pythonWithTools = pkgs.python312.withPackages (ps:
        with ps; [
          pip
          ipython
          black
        ]);
    in
    {
      default = pkgs.mkShell {
        name = "dots";

        packages = with pkgs; [
          bashInteractive
          gcc

          nixfmt
          deadnix
          statix

          typos
          nodePackages.prettier
        ];

        inherit (self.checks.${system}.pre-commit-check) shellHook;
      };

      # Python 项目开发环境
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
          echo "项目级 venv 示例:"
          echo "  uv venv && source .venv/bin/activate"
          echo "  uv pip install -r requirements.txt"
        '';
      };
    }
  );

  # =====================================================================================
  # Formatter
  # =====================================================================================

  formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt);
}
