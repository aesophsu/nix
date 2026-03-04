{ config, lib, ... }:

let
  envExtra = ''
    export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
  '';

  # Uncomment after installing conda/miniforge if needed
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
    # Pin dotDir to avoid default-change warning
    dotDir = config.home.homeDirectory;
    initContent = lib.mkAfter (envExtra + initContent);
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

}
