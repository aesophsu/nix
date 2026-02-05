{ pkgs, config, ... }:

let
  mcpFilesystemPython = pkgs.callPackage ../../../misc/mcp/filesystem { };
in
{
  home.packages = with pkgs; [
    nix-index
    nix-tree
    gnupg
    uv
    tree
    wget
    nodejs
    go
  ];

  home.file.".cursor/mcp.json".text = ''
    {
      "mcpServers": {
        "filesystem": {
          "command": "${mcpFilesystemPython}/bin/mcp-filesystem",
          "args": [
            "${config.home.homeDirectory}"
          ]
        },
        "terminal": {
          "command": "/Users/sue/dev/terminal_mcp/mcp-terminal-server",
          "args": [],
          "env": {
            "MCP_COMMAND_TIMEOUT": "30",
            "MCP_SHELL": "/bin/zsh"
          }
        },
        "zotero-mcp": {
          "command": "${pkgs.uv}/bin/uvx",
          "args": [
            "--upgrade",
            "zotero-mcp"
          ],
          "env": {
            "ZOTERO_LOCAL": "true",
            "ZOTERO_API_KEY": "",
            "ZOTERO_LIBRARY_ID": "",
            "ZOTERO_LIBRARY_TYPE": "user"
          }
        },
        "pdf-mcp": {
          "command": "${pkgs.uv}/bin/uvx",
          "args": [
            "pdf-reader-mcp"
          ]
        },
        "playwright": {
          "command": "${pkgs.nodejs}/bin/npx",
          "args": [
            "@playwright/mcp@latest"
          ],
          "env": {
            "PLAYWRIGHT_BROWSERS_PATH": "0"
          }
        }
      }
    }
  '';

  # Modern replacement for `ls`
  programs.eza = {
    enable = true;
    enableNushellIntegration = false; # managed by shells/config.nu
    git = true;
    icons = "auto"; # show icons when terminal supports it
  };

  # Syntax-highlighted `cat`
  programs.bat = {
    enable = true;
    config = {
      pager = "less -FR"; # bat pager
    };
  };

  # Command-line fuzzy finder
  programs.fzf.enable = true;

  # Fast `tldr` (Rust-based)
  programs.tealdeer = {
    enable = true;
    enableAutoUpdates = true;
    settings = {
      display = {
        compact = false;
        use_pager = true;
      };
      updates = {
        auto_update = false;
        auto_update_interval_hours = 720; # 30 days
      };
    };
  };

  # Smarter `cd` command with directory ranking
  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableNushellIntegration = true;
  };

  # Shell history with SQLite (context-aware)
  programs.atuin = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableNushellIntegration = true;
  };
}
