{
  self,
  nixpkgs,
  pre-commit-hooks,
  ...
}@inputs:
let
  system = "aarch64-darwin";
  inherit (inputs.nixpkgs) lib;
  projectRoots = {
    qdrant = "/Users/sue/Code/grobid-qdrant-stack";
    gptResearch = "/Users/sue/Code/gpt-researcher";
  };

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

  stellaHost = {
    name = "stella";
    platform = "darwin";
    system = system;
    hostPath = "hosts/stella";
    homePath = "hosts/stella/home.nix";
    roles = [ "desktop" ];
    tags = [
      "primary"
      "macbook-air-m4"
    ];
    enabled = true;
  };

  checkNames = [
    "smoke-eval"
  ]
  ++ lib.optionals (builtins.hasAttr system pre-commit-hooks.lib) [ "pre-commit" ];

  pkgs = nixpkgs.legacyPackages.${system};
  tests = darwinOutputs.evalTests or { };
  commonLangPackages = with pkgs; [
    go
    nodejs_22
    rustc
    cargo
    rustfmt
    clippy
    pkg-config
    openssl
  ];
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

  devShells = {
    "aarch64-darwin" =
      let
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

        qdrant = pkgs.mkShell {
          name = "qdrant-dev";
          packages = commonLangPackages ++ (with pkgs; [
            python312
            uv
            docker
            docker-compose
            jq
          ]);

          shellHook = ''
            export PROJECT_ROOT="${projectRoots.qdrant}"
            echo "qdrant shell ready"
            echo "project: $PROJECT_ROOT"
            echo "Go: $(go version)"
            echo "Node: $(node -v) / npm: $(npm -v)"
            echo "Rust: $(rustc --version)"
            echo "Python: $(python --version)"
            echo "uv: $(uv --version 2>/dev/null || true)"
          '';
        };

        gpt-research = pkgs.mkShell {
          name = "gpt-research-dev";
          packages = commonLangPackages ++ (with pkgs; [
            python312
            uv
            pnpm
            jq
          ]);

          shellHook = ''
            export PROJECT_ROOT="${projectRoots.gptResearch}"
            echo "gpt-research shell ready"
            echo "project: $PROJECT_ROOT"
            echo "Go: $(go version)"
            echo "Node: $(node -v) / npm: $(npm -v)"
            echo "Rust: $(rustc --version)"
            echo "Python: $(python --version)"
            echo "uv: $(uv --version 2>/dev/null || true)"
          '';
        };
      };
  };

  formatter = {
    "aarch64-darwin" = pkgs.nixfmt;
  };
}
