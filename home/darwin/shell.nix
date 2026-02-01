{ config, lib, ... }:
let
  envExtra = ''
    export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
  '';

  # conda/miniforge 按需安装后取消注释
  initContent = ''
    # if [ -f "/opt/homebrew/Caskroom/miniforge/base/etc/profile.d/conda.sh" ]; then
    #     . "/opt/homebrew/Caskroom/miniforge/base/etc/profile.d/conda.sh"
    # fi
  '';
in
{
  programs.bash = {
    enable = true;
    bashrcExtra = lib.mkAfter (envExtra + initContent);
  };

  programs.zsh = {
    enable = true;
    # 锁定当前行为，消除 dotDir 默认值变更警告
    dotDir = config.home.homeDirectory;
    initContent = lib.mkAfter (envExtra + initContent);
  };

}
