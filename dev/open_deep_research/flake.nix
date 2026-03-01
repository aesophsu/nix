{
  description = "Dev shell for open_deep_research (moved to dev/open_deep_research)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
  };

  outputs = { self, nixpkgs }: let
    system = "x86_64-darwin";
    pkgs = import nixpkgs { inherit system; };
  in {
    devShells.default = pkgs.mkShell {
      buildInputs = with pkgs; [
        python311
        python311Packages.pip
        nodejs
        npm
        ruff
        mypy
        pytest
        uvicorn
      ];

      shellHook = ''
        export PYTHONNOUSERSITE=1
        export VIRTUAL_ENV_DISABLE_PROMPT=1

        # Create and activate a lightweight venv inside the project dir
        if [ ! -d .venv ]; then
          python -m venv .venv
        fi
        # shellcheck disable=SC1091
        . .venv/bin/activate

        pip install --upgrade pip setuptools wheel

        # If the repo is checked out next to this nix dir, install it editable
        if [ -d ../../open_deep_research ]; then
          pip install --upgrade -e ../../open_deep_research || true
        fi

        # Install LangGraph CLI if missing
        if ! command -v langgraph >/dev/null 2>&1; then
          pip install --upgrade langgraph-cli || true
        fi

        # Optional: install MCP JS filesystem tool globally for convenience
        if command -v npm >/dev/null 2>&1; then
          npm install --no-audit --no-fund -g @modelcontextprotocol/server-filesystem || true
        fi

        # Copy example env if user hasn't created one
        if [ ! -f .env ] && [ -f ../../open_deep_research/.env.example ]; then
          cp ../../open_deep_research/.env.example .env || true
        fi
      '';
    };
  };
}
