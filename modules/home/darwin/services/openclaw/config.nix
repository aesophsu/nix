{
  config,
  pkgs,
  ...
}:
let
  inherit (config._module.args.openclawPlugins)
    feishuPluginId
    memoryLancedbProId
    memoryLancedbProInstall
    tavilyPluginId
    tavilyPluginInstall
    ;
  feishuAppId = "cli_a926fc773df85cc7";
  managedOpenclawConfig = {
    auth.profiles."openai-codex:default" = {
      provider = "openai-codex";
      mode = "oauth";
    };
    agents.defaults = {
      model.primary = "openai-codex/gpt-5.4";
      workspace = "${config.home.homeDirectory}/.openclaw/workspace";
      compaction.mode = "safeguard";
      sandbox.mode = "off";
      memorySearch.enabled = false;
    };
    channels = {
      feishu = {
        enabled = true;
        appId = feishuAppId;
        appSecret = "\${FEISHU_APP_SECRET}";
        domain = "feishu";
        connectionMode = "websocket";
        requireMention = true;
        dmPolicy = "pairing";
        groupPolicy = "allowlist";
        allowFrom = [
          "ou_0a0b162f4521f168e4f15494e3e2714f"
        ];
        groupAllowFrom = [
          "ou_0a0b162f4521f168e4f15494e3e2714f"
        ];
        tools = {
          doc = false;
          wiki = false;
        };
      };
    };
    gateway = {
      mode = "local";
      auth.mode = "token";
      trustedProxies = [
        "127.0.0.1"
        "::1"
      ];
    };
    tools = {
      profile = "coding";
      alsoAllow = [
        "group:web"
        "tavily_search"
        "tavily_extract"
        "tavily_crawl"
        "tavily_map"
        "tavily_research"
      ];
      deny = [ "group:runtime" ];
      fs.workspaceOnly = true;
    };
    plugins = {
      allow = [
        feishuPluginId
        memoryLancedbProId
        tavilyPluginId
      ];
      slots.memory = memoryLancedbProId;
      entries = {
        feishu.enabled = true;
        ${tavilyPluginId} = {
          enabled = true;
          config = {
            searchDepth = "advanced";
            maxResults = 5;
            includeAnswer = true;
            includeRawContent = false;
            timeoutSeconds = 30;
          };
        };
        ${memoryLancedbProId} = {
          enabled = true;
          config = {
            embedding = {
              provider = "openai-compatible";
              apiKey = "\${JINA_API_KEY}";
              model = "jina-embeddings-v5-text-small";
              baseURL = "https://api.jina.ai/v1";
              dimensions = 1024;
              taskQuery = "retrieval.query";
              taskPassage = "retrieval.passage";
              normalized = true;
            };
            dbPath = "${config.home.homeDirectory}/.openclaw/memory/lancedb-pro";
            autoCapture = false;
            autoRecall = false;
            enableManagementTools = false;
            sessionStrategy = "systemSessionMemory";
            retrieval = {
              mode = "hybrid";
              rerank = "cross-encoder";
              rerankProvider = "jina";
              rerankApiKey = "\${JINA_API_KEY}";
              rerankModel = "jina-reranker-v3";
              rerankEndpoint = "https://api.jina.ai/v1/rerank";
            };
            selfImprovement.enabled = false;
            scopes = {
              default = "project:openclaw-nix";
              definitions = {
                global.description = "Stable cross-context personal memory only";
                "project:openclaw-nix".description = "Primary OpenClaw + Nix working memory";
                "agent:admin".description = "Privileged local admin and ops memory";
                "project:research".description = "Research project memory";
                "project:medical-rag".description = "Medical RAG project memory";
              };
              agentAccess = {
                main = [
                  "global"
                  "project:openclaw-nix"
                ];
              };
            };
          };
        };
      };
      installs.${memoryLancedbProId} = memoryLancedbProInstall;
      installs.${tavilyPluginId} = tavilyPluginInstall;
    };
  };
  managedOpenclawHmConfig = managedOpenclawConfig // {
    channels = builtins.removeAttrs managedOpenclawConfig.channels [ "feishu" ];
    secrets.providers = { };
  };
  declarativeOpenclawConfig = pkgs.writeText "openclaw.json" (builtins.toJSON managedOpenclawConfig);
in
{
  _module.args.openclawConfig = {
    inherit
      declarativeOpenclawConfig
      feishuAppId
      managedOpenclawConfig
      managedOpenclawHmConfig
      ;
  };
}
