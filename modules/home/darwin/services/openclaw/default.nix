{
  config,
  lib,
  myvars,
  nix-openclaw,
  pkgs,
  ...
}:
let
  proxyEnv = myvars.networking.proxy.env {
    inherit (myvars.networking.mihomo) httpProxy socksProxy;
  };
  inherit (config._module.args.openclawPackage)
    fixedGateway
    openclawPackageDir
    upstreamPackages
    ;
  inherit (config._module.args.openclawPlugins)
    feishuPluginId
    memoryLancedbProId
    memoryLancedbProInstall
    memoryLancedbProSrc
    memoryLancedbProVersion
    tavilyPluginId
    tavilyPluginInstall
    tavilyPluginSrc
    tavilyPluginVersion
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
  gatewayLaunchdPath = lib.concatStringsSep ":" [
    "${config.home.homeDirectory}/.local/npm/bin"
    "${config.home.homeDirectory}/.local/bin"
    "${config.home.homeDirectory}/.npm-global/bin"
    "${config.home.homeDirectory}/bin"
    "${config.home.homeDirectory}/.volta/bin"
    "${config.home.homeDirectory}/.asdf/shims"
    "${config.home.homeDirectory}/.bun/bin"
    "${config.home.homeDirectory}/Library/Application Support/fnm/aliases/default/bin"
    "${config.home.homeDirectory}/.fnm/aliases/default/bin"
    "${config.home.homeDirectory}/Library/pnpm"
    "${config.home.homeDirectory}/.local/share/pnpm"
    "/opt/homebrew/bin"
    "/usr/local/bin"
    "/usr/bin"
    "/bin"
    "/usr/sbin"
    "/sbin"
  ];
in
{
  imports = [
    nix-openclaw.homeManagerModules.openclaw
    ./package.nix
    ./plugins.nix
  ];

  home.file.".openclaw/.env".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.secrets/openclaw.env";
  home.file.".openclaw/openclaw.json".force = true;
  home.file.".local/bin/openclaw" = {
    executable = true;
    text = ''
      #!/bin/sh
      export OPENCLAW_NIX_MODE="''${OPENCLAW_NIX_MODE-1}"
      export PATH="${gatewayLaunchdPath}:$PATH"
      export http_proxy="${proxyEnv.http_proxy}"
      export https_proxy="${proxyEnv.https_proxy}"
      export all_proxy="${proxyEnv.all_proxy}"
      export HTTP_PROXY="${proxyEnv.HTTP_PROXY}"
      export HTTPS_PROXY="${proxyEnv.HTTPS_PROXY}"
      export ALL_PROXY="${proxyEnv.ALL_PROXY}"
      export no_proxy="${proxyEnv.no_proxy}"
      export NO_PROXY="${proxyEnv.NO_PROXY}"

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

      if [ -z "$OPENCLAW_BUNDLED_SKILLS_DIR" ]; then
        openclaw_pkg="${openclawPackageDir}"
        if [ -n "$openclaw_pkg" ] && [ -d "$openclaw_pkg/skills" ]; then
          export OPENCLAW_BUNDLED_SKILLS_DIR="$openclaw_pkg/skills"
        fi
      fi

      exec ${fixedGateway}/bin/openclaw "$@"
    '';
  };
  home.file.".openclaw/identity/.keep".text = "";
  home.activation.openclawDeclarativeConfigLink = lib.hm.dag.entryAfter [ "openclawConfigFiles" ] ''
    target="${config.home.homeDirectory}/.openclaw/openclaw.json"
    run --quiet ${lib.getExe' pkgs.coreutils "rm"} -f "$target"
    run --quiet ${lib.getExe' pkgs.coreutils "cp"} ${declarativeOpenclawConfig} "$target"
    run --quiet ${lib.getExe' pkgs.coreutils "chmod"} 600 "$target"
  '';
  home.activation.openclawMemoryLancedbProInstall =
    lib.hm.dag.entryAfter [ "openclawDeclarativeConfigLink" ]
      ''
        plugin_dir="${config.home.homeDirectory}/.openclaw/extensions/${memoryLancedbProId}"
        tmp_dir="$(${lib.getExe' pkgs.coreutils "mktemp"} -d)"
        current_version=""
        if [ -f "$plugin_dir/package.json" ]; then
          current_version="$(${lib.getExe pkgs.jq} -r '.version // empty' "$plugin_dir/package.json" 2>/dev/null || true)"
        fi
        if [ "$current_version" != "${memoryLancedbProVersion}" ]; then
          rm -rf "$plugin_dir"
          run --quiet ${lib.getExe' pkgs.coreutils "mkdir"} -p "$plugin_dir"
          run --quiet ${lib.getExe' pkgs.gnutar "tar"} --use-compress-program=${lib.getExe' pkgs.gzip "gzip"} -xf ${memoryLancedbProSrc} -C "$tmp_dir"
          src_dir="$(find "$tmp_dir" -mindepth 1 -maxdepth 1 -type d | head -n 1)"
          run --quiet cp -R "$src_dir"/. "$plugin_dir"/
          (
            cd "$plugin_dir"
            export npm_config_cache="${config.home.homeDirectory}/.cache/npm"
            ${lib.getExe' pkgs.nodejs_22 "npm"} install --omit=dev --ignore-scripts
          )
        fi
      '';
  home.activation.openclawTavilyInstall =
    lib.hm.dag.entryAfter [ "openclawMemoryLancedbProInstall" ]
      ''
        plugin_dir="${config.home.homeDirectory}/.openclaw/extensions/${tavilyPluginId}"
        tmp_dir="$(${lib.getExe' pkgs.coreutils "mktemp"} -d)"
        current_version=""
        if [ -f "$plugin_dir/package.json" ]; then
          current_version="$(${lib.getExe pkgs.jq} -r '.version // empty' "$plugin_dir/package.json" 2>/dev/null || true)"
        fi
        if [ "$current_version" != "${tavilyPluginVersion}" ]; then
          rm -rf "$plugin_dir"
          run --quiet ${lib.getExe' pkgs.coreutils "mkdir"} -p "$plugin_dir"
          run --quiet ${lib.getExe' pkgs.gnutar "tar"} --use-compress-program=${lib.getExe' pkgs.gzip "gzip"} -xf ${tavilyPluginSrc} -C "$tmp_dir"
          src_dir="$(find "$tmp_dir" -mindepth 1 -maxdepth 1 -type d | head -n 1)"
          run --quiet cp -R "$src_dir"/. "$plugin_dir"/
          (
            cd "$plugin_dir"
            export npm_config_cache="${config.home.homeDirectory}/.cache/npm"
            ${lib.getExe' pkgs.nodejs_22 "npm"} install --omit=dev --ignore-scripts
          )
        fi
      '';
  home.activation.openclawRuntimeHygiene = lib.hm.dag.entryAfter [ "openclawTavilyInstall" ] ''
    openclaw_pkg="${openclawPackageDir}"
    rm -rf "${config.home.homeDirectory}/.openclaw/extensions/feishu-openclaw-plugin"
    for plugin_dir in "${config.home.homeDirectory}/.openclaw/extensions/${memoryLancedbProId}" "${config.home.homeDirectory}/.openclaw/extensions/${tavilyPluginId}"; do
      if [ -d "$plugin_dir" ] && [ -n "$openclaw_pkg" ] && [ -d "$openclaw_pkg" ]; then
        run --quiet ${lib.getExe' pkgs.coreutils "mkdir"} -p "$plugin_dir/node_modules"
        run --quiet ${lib.getExe' pkgs.coreutils "ln"} -sfn "$openclaw_pkg" "$plugin_dir/node_modules/openclaw"
      fi
    done

    run --quiet ${lib.getExe' pkgs.coreutils "mkdir"} -p "${config.home.homeDirectory}/.openclaw/credentials"
    run --quiet ${lib.getExe' pkgs.coreutils "chmod"} 700 "${config.home.homeDirectory}/.openclaw/credentials"
  '';
  home.activation.openclawAgentsSkillsMirror = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    src="${config.home.homeDirectory}/.codex/superpowers/skills"
    dst="${config.home.homeDirectory}/.agents/skills/superpowers"

    if [ -d "$src" ]; then
      run --quiet ${lib.getExe' pkgs.coreutils "mkdir"} -p "${config.home.homeDirectory}/.agents/skills"
      if [ -L "$dst" ] || [ -e "$dst" ]; then
        run --quiet ${lib.getExe' pkgs.coreutils "rm"} -rf "$dst"
      fi
      run --quiet ${lib.getExe' pkgs.coreutils "mkdir"} -p "$dst"
      run --quiet ${lib.getExe' pkgs.coreutils "cp"} -LR "$src"/. "$dst"/
    fi
  '';
  launchd.agents."com.steipete.openclaw.gateway".config.ProgramArguments = lib.mkForce [
    "${config.home.homeDirectory}/.local/bin/openclaw"
    "gateway"
    "--port"
    "18789"
  ];
  launchd.agents."com.steipete.openclaw.gateway".config.EnvironmentVariables.PATH =
    lib.mkForce gatewayLaunchdPath;

  programs.openclaw = {
    enable = true;
    package = fixedGateway;
    appPackage = upstreamPackages.openclaw-app or null;
    documents = ./documents;
    bundledPlugins.goplaces.enable = false;

    instances.default = {
      enable = true;
      config = managedOpenclawHmConfig;
    };
  };
}
