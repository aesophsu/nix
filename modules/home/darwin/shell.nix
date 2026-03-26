{
  config,
  lib,
  myvars,
  ...
}:

let
  npmGlobalPrefix = "${config.home.homeDirectory}/.local/npm";
  proxyEnv = myvars.networking.proxy.env {
    inherit (myvars.networking.mihomo) httpProxy socksProxy;
  };
  defaultProxyEnv = lib.optionalAttrs (myvars.networking.proxy.policy.cliDefault == "on") proxyEnv;
  shellAliases = {
    urldecode = "python3 -c 'import sys, urllib.parse as ul; print(ul.unquote_plus(sys.stdin.read()))'";
    urlencode = "python3 -c 'import sys, urllib.parse as ul; print(ul.quote_plus(sys.stdin.read()))'";
  };
  envExtra = ''
    export NPM_CONFIG_PREFIX="${npmGlobalPrefix}"
    export PATH="$PATH:${config.home.homeDirectory}/.local/bin:${npmGlobalPrefix}/bin"
    if [ -f "${config.home.homeDirectory}/.secrets/jina-api-key" ]; then
      export JINA_API_KEY="$(cat "${config.home.homeDirectory}/.secrets/jina-api-key")"
    fi
  '';
  initContent = ''
    # if [ -f "/opt/homebrew/Caskroom/miniforge/base/etc/profile.d/conda.sh" ]; then
    #     . "/opt/homebrew/Caskroom/miniforge/base/etc/profile.d/conda.sh"
    # fi
  '';
in
{
  home.sessionPath = [
    "/opt/homebrew/bin"
    "${config.home.homeDirectory}/.local/bin"
    "${config.xdg.stateHome}/nix/profiles/home-manager/home-path/bin"
  ];
  home.sessionVariables = defaultProxyEnv;
  home.shellAliases = shellAliases;

  programs.bash = {
    enable = true;
    enableCompletion = true;
    bashrcExtra = lib.mkAfter (envExtra + initContent);
  };

  programs.zsh = {
    enable = true;
    dotDir = config.home.homeDirectory;
    profileExtra = ''
      # macOS login zsh runs path_helper after .zshenv, which can drop
      # Home Manager's PATH prefixes. Re-source session vars here so login
      # shells keep the declarative PATH ordering.
      . "${config.home.profileDirectory}/etc/profile.d/hm-session-vars.sh"
    '';
    initContent = lib.mkAfter (envExtra + initContent);
  };

  programs.nushell = {
    enable = true;
    configFile.source = ./config.nu;
    inherit shellAliases;
  };
}
