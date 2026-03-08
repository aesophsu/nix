{ config, lib, ... }:

let
  npmGlobalPrefix = "${config.home.homeDirectory}/.local/npm";
  envExtra = ''
    # Keep codex CLI and other npm -g tools outside the Nix store.
    export NPM_CONFIG_PREFIX="${npmGlobalPrefix}"
    export PATH="$PATH:${npmGlobalPrefix}/bin"
    # Use Node's Corepack-managed package managers (pnpm/yarn) with Nix Node.
    corepack enable >/dev/null 2>&1 || true
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
}
