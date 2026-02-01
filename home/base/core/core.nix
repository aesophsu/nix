{ pkgs, ... }:
{
  home.packages = with pkgs; [
    nix-index
    nix-tree
    gnupg
    tree
    wget
  ];

  # Modern replacement for `ls`
  programs.eza = {
    enable = true;
    enableNushellIntegration = false; # 由 shells/config.nu 管理
    git = true;
    icons = "auto"; # 终端支持时显示图标
  };

  # Syntax-highlighted `cat`
  programs.bat = {
    enable = true;
    config = {
      pager = "less -FR"; # bat 输出分页
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
        auto_update_interval_hours = 720; # 30 天
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
