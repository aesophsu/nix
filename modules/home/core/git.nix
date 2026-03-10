{
  config,
  lib,
  myvars,
  ...
}:

{
  # Remove existing .gitconfig before activation so this config is used
  home.activation.removeExistingGitconfig = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    rm -f ${config.home.homeDirectory}/.gitconfig
  '';

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

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      diff-so-fancy = true;
      line-numbers = true;
      true-color = "always";
    };
  };

  programs.lazygit.enable = true;

  programs.gitui.enable = false;
}
