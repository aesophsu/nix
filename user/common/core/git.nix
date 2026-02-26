{
  config,
  lib,
  pkgs,
  myvars,
  ...
}:

{
  # Remove existing .gitconfig before activation so this config is used
  home.activation.removeExistingGitconfig = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    rm -f ${config.home.homeDirectory}/.gitconfig
  '';

  # GitHub CLI (gh)
  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "ssh";
      prompt = "enabled"; # gh interactive prompt
      aliases = {
        co = "pr checkout";
        pv = "pr view";
      };
    };
    hosts = {
      "github.com" = {
        "users" = {
          "aesophsu" = null;
        };
        "user" = "aesophsu";
      };
    };
  };

  # Main Git config; work dir uses ~/work/.gitconfig via includes
  programs.git = {
    enable = true;
    lfs.enable = true;

    includes = [
      {
        path = "~/work/.gitconfig";
        condition = "gitdir:~/work/";
      }
    ];

    settings = {
      user.email = myvars.useremail;
      user.name = myvars.userfullname;
      init.defaultBranch = "main";
      trim.bases = "develop,master,main"; # git-trim base branches
      push.autoSetupRemote = true;
      pull.rebase = true;
      log.date = "iso"; # log date format
      url = {
        "ssh://git@github.com/aesophsu" = {
          insteadOf = "https://github.com/aesophsu";
        };
      };
    };
  };

  # delta: Git diff syntax highlighting
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      diff-so-fancy = true;
      line-numbers = true;
      true-color = "always";
    };
  };

  # lazygit：Git TUI
  programs.lazygit.enable = true;

  # gitui: alternative Git TUI (disabled)
  programs.gitui.enable = false;
}
