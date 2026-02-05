# OpenClaw declarative config (nix-openclaw)
# No Telegram; local WebChat/CLI. Package and PATH wrapper: lib/openclaw-package.nix

{ config, lib, pkgs, openclawPackageNoOracle, ... }:

let
  stateDir = "${config.home.homeDirectory}/.openclaw";
  configPath = "${stateDir}/openclaw.json";

  # Minimal config: single source for programs.openclaw.config and fallback JSON
  # DeepSeek API; set DEEPSEEK_API_KEY (see https://platform.deepseek.com)
  openclawMinimalConfig = {
    gateway = {
      mode = "local";
      auth.token = "local-dev"; # local mode needs non-empty token; use secrets in prod
    };
    agents = {
      defaults = { model = { primary = "deepseek/deepseek-chat"; }; };
    };
    # Custom provider: DeepSeek (OpenAI-compatible)
    models = {
      mode = "merge";
      providers = {
        deepseek = {
          baseUrl = "https://api.deepseek.com/v1";
          apiKey = "\${DEEPSEEK_API_KEY}"; # read from env at runtime; do not commit keys
          api = "openai-completions";
          models = [
            { id = "deepseek-chat"; name = "DeepSeek Chat (V3.2)"; }
            { id = "deepseek-reasoner"; name = "DeepSeek Reasoner (reasoning mode)"; }
          ];
        };
      };
    };
  };

  openclawConfigFallbackFile = pkgs.writeText "openclaw-fallback.json" (builtins.toJSON openclawMinimalConfig);
in
{
  programs.openclaw = {
    enable = true;
    package = openclawPackageNoOracle;
    documents = ./documents;

    config = openclawMinimalConfig;

    # First-party plugins: screenshot, summarize, etc. (optional)
    firstParty = {
      summarize.enable = true;
      peekaboo.enable = true;
      oracle.enable = false;
      poltergeist.enable = false;
      sag.enable = false;
      camsnap.enable = false;
    };

    # Instance and launchd (must be under programs.openclaw)
    instances.default = {
      enable = true;
      launchd.enable = true;
      plugins = [ ];
    };
  };

  # If openclaw.json is {}, write this minimal config so gateway can start
  home.activation.openclawConfigFallback = lib.hm.dag.entryAfter [ "openclawConfigFiles" ] ''
    if [ -f ${configPath} ] && [ "$(cat ${configPath} 2>/dev/null)" = "{}" ]; then
      rm -f ${configPath}
      ln -sfn ${openclawConfigFallbackFile} ${configPath}
      echo "openclaw: replaced empty config with fallback (gateway.mode=local)"
    fi
  '';
}
