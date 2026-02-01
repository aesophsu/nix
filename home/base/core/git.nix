{
  config,
  lib,
  pkgs,
  myvars,
  ...
}:
{
  # 激活前删除已有 .gitconfig，确保使用本配置
  home.activation.removeExistingGitconfig = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    rm -f ${config.home.homeDirectory}/.gitconfig
  '';

  # GitHub CLI (gh)
  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "ssh";
      prompt = "enabled"; # gh 交互式提示
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

  # Git 主配置；工作目录通过 includes 使用 ~/work/.gitconfig
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
      trim.bases = "develop,master,main"; # git-trim 基准分支
      push.autoSetupRemote = true;
      pull.rebase = true;
      log.date = "iso"; # 日志日期格式
      url = {
        "ssh://git@github.com/aesophsu" = {
          insteadOf = "https://github.com/aesophsu";
        };
      };
    };
  };

  # delta：Git diff 语法高亮
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

  # gitui：备用 Git TUI（未启用）
  programs.gitui.enable = false;
}
