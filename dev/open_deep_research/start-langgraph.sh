#!/usr/bin/env bash
set -euo pipefail

# Start LangGraph Studio (prefers uvx if available)
if command -v uvx >/dev/null 2>&1; then
  uvx --refresh --from "langgraph-cli[inmem]" --with-editable ../../open_deep_research --python 3.11 langgraph dev --allow-blocking
else
  # Fall back to langgraph CLI directly
  if ! command -v langgraph >/dev/null 2>&1; then
    echo "langgraph not found in PATH; install langgraph-cli in the devShell or system Python." >&2
    exit 2
  fi
  langgraph dev
fi
