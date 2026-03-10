{ config, ... }:
{
  _module.args.openclawSecrets = {
    envFileSource = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.secrets/openclaw.env";
    wrapperSecretExports = ''
      if [ -f "${config.home.homeDirectory}/.secrets/feishu-app-id" ] && [ -z "$FEISHU_APP_ID" ]; then
        export FEISHU_APP_ID="$(cat "${config.home.homeDirectory}/.secrets/feishu-app-id")"
      fi
      if [ -f "${config.home.homeDirectory}/.secrets/feishu-app-secret" ] && [ -z "$FEISHU_APP_SECRET" ]; then
        export FEISHU_APP_SECRET="$(cat "${config.home.homeDirectory}/.secrets/feishu-app-secret")"
      fi
      if [ -f "${config.home.homeDirectory}/.secrets/jina-api-key" ] && [ -z "$JINA_API_KEY" ]; then
        export JINA_API_KEY="$(cat "${config.home.homeDirectory}/.secrets/jina-api-key")"
      fi
      if [ -f "${config.home.homeDirectory}/.secrets/tavily-api-key" ] && [ -z "$TAVILY_API_KEY" ]; then
        export TAVILY_API_KEY="$(cat "${config.home.homeDirectory}/.secrets/tavily-api-key")"
      fi
      if [ -f "${config.home.homeDirectory}/.secrets/firecrawl-api-key" ] && [ -z "$FIRECRAWL_API_KEY" ]; then
        export FIRECRAWL_API_KEY="$(cat "${config.home.homeDirectory}/.secrets/firecrawl-api-key")"
      fi
    '';
  };
}
