self: super: {
  # Simple wrapper for the Playwright MCP server.
  #
  # This keeps the MCP command path stable via Nix, while still
  # using npm/npx under the hood to fetch and run @playwright/mcp.
  #
  # Usage (in configs):
  #   "${pkgs.playwright-mcp}/bin/playwright-mcp"
  playwright-mcp = super.writeShellScriptBin "playwright-mcp" ''
    exec ${super.nodejs}/bin/npx @playwright/mcp@latest "$@"
  '';

  # Wrapper for GitHub MCP (Copilot MCP via mcp-remote).
  #
  # Provides a stable "github-mcp" executable that runs:
  #   npx -y mcp-remote https://api.githubcopilot.com/mcp/
  #
  # Usage:
  #   "${pkgs.github-mcp}/bin/github-mcp"
  github-mcp = super.writeShellScriptBin "github-mcp" ''
    exec ${super.nodejs}/bin/npx -y mcp-remote https://api.githubcopilot.com/mcp/ "$@"
  '';

  # Wrapper for your local terminal MCP server.
  #
  # Assumes you have cloned / built:
  #   $HOME/Code/terminal_mcp/mcp-terminal-server
  #
  # Usage:
  #   "${pkgs.mcp-terminal}/bin/mcp-terminal"
  mcp-terminal = super.writeShellScriptBin "mcp-terminal" ''
    exec "$HOME/Code/terminal_mcp/mcp-terminal-server" "$@"
  '';
}


