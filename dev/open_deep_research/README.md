Dev helpers for Open Deep Research (moved to dev/open_deep_research)

Usage

- Enter the flake-based devShell (preferred):

```
cd ~/Code/nix/dev/open_deep_research
nix develop
```

- Or use the fallback shell.nix:

```
cd ~/Code/nix/dev/open_deep_research
nix-shell
```

Inside the shell the `shellHook` attempts to:
- create `.venv` and activate it
- `pip install -e ../../open_deep_research` if the repository is checked out next to `~/Code/nix`
- `pip install langgraph-cli` if `langgraph` is missing
- copy `.env.example` from the repo if `.env` is missing

Start LangGraph Studio:

```
./start-langgraph.sh
```

Adjust paths if your repo is in a different location.
