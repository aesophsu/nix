{ config, ... }:
{
  programs.zsh = {
    enable = true;
    dotDir = config.home.homeDirectory;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    shellAliases = {
      ll = "ls -lah";
      gs = "git status";
      v = "nvim";
    };
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      "$schema" = "https://starship.rs/config-schema.json";
      character = {
        success_symbol = "[➜](bold green)";
        error_symbol = "[➜](bold red)";
      };
      os.disabled = true;
      directory = {
        truncation_length = 3;
        fish_style_pwd_dir_length = 1;
      };
      aws.disabled = true;
      gcloud.disabled = true;
      kubernetes.disabled = true;
    };
  };
}
