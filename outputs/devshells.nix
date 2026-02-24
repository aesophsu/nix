{ self, lib, nixpkgs }:
{ darwinSystemNames }:
lib.genAttrs darwinSystemNames (
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
    preCommitShellHook =
      if lib.hasAttrByPath [ "checks" system "pre-commit" "shellHook" ] self then
        self.checks.${system}.pre-commit.shellHook
      else
        "";
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
        just
        nushell
      ];

      shellHook = preCommitShellHook;
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
  }
)
