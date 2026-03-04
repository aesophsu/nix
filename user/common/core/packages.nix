{ pkgs, ... }:

{
  home.packages = with pkgs; [
    nix-index
    nix-tree
    gnupg
    codex
    ollama
    tree
    wget
    nodejs
    go
  ];

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
