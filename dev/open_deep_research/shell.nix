{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    python311
    python311Packages.pip
    nodejs
    ruff
    mypy
    pytest
    uvicorn
  ];

  shellHook = ''
    export PYTHONNOUSERSITE=1
    export VIRTUAL_ENV_DISABLE_PROMPT=1

    if [ ! -d .venv ]; then
      python -m venv .venv
    fi
    . .venv/bin/activate
    pip install --upgrade pip

    if [ -d ../../open_deep_research ]; then
      pip install --upgrade -e ../../open_deep_research || true
    fi

    if ! command -v langgraph >/dev/null 2>&1; then
      pip install --upgrade langgraph-cli || true
    fi

    if [ ! -f .env ] && [ -f ../../open_deep_research/.env.example ]; then
      cp ../../open_deep_research/.env.example .env || true
    fi
  '';
}
