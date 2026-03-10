{ config, lib, myvars, nix-openclaw, pkgs, ... }:
let
  upstreamPackages = nix-openclaw.packages.${pkgs.stdenv.hostPlatform.system};
  proxyEnv =
    myvars.networking.proxy.env {
      inherit (myvars.networking.mihomo) httpProxy socksProxy;
    };
  feishuAppId = "cli_a926fc773df85cc7";
  feishuPluginId = "feishu";
  feishuPluginInstall = {
    source = "npm";
    spec = "@larksuiteoapi/feishu-openclaw-plugin@2026.3.8";
    installPath = "${config.home.homeDirectory}/.openclaw/extensions/${feishuPluginId}";
    version = "2026.3.8";
    resolvedName = "@larksuiteoapi/feishu-openclaw-plugin";
    resolvedVersion = "2026.3.8";
    resolvedSpec = "@larksuiteoapi/feishu-openclaw-plugin@2026.3.8";
    integrity = "sha512-77PzCEESdPgqL9jgoV8I3difKOuC/iRiECYLUT+2rLRD1Oy+CHtTXuYwHwztHvbY2sWitev/5rN/TseDHo2FVg==";
    shasum = "d4acc5a0433aaf77b0d87a028fa627b38efdb4cd";
    resolvedAt = "2026-03-08T08:28:44.852Z";
    installedAt = "2026-03-08T08:29:19.942Z";
  };
  memoryLancedbProId = "memory-lancedb-pro";
  memoryLancedbProVersion = "1.1.0-beta.6";
  memoryLancedbProRev = "cc8bf7cabc1b24c7769e15af59f41b49f43442b3";
  memoryLancedbProSrc = pkgs.fetchurl {
    url = "https://github.com/win4r/memory-lancedb-pro/archive/${memoryLancedbProRev}.tar.gz";
    hash = "sha256-W1aeASg6oxJ/pm88lZsf2j4kbbW1mCGycP4HGk9Yuuc=";
  };
  memoryLancedbProInstall = {
    source = "path";
    sourcePath = "${memoryLancedbProSrc}";
    installPath = "${config.home.homeDirectory}/.openclaw/extensions/${memoryLancedbProId}";
    version = memoryLancedbProVersion;
  };
  tavilyPluginId = "openclaw-tavily";
  tavilyPluginVersion = "0.2.1";
  tavilyPluginRev = "6db474508f44854864d6c47368c84962ef012120";
  tavilyPluginSrc = pkgs.fetchurl {
    url = "https://github.com/framix-team/openclaw-tavily/archive/${tavilyPluginRev}.tar.gz";
    hash = "sha256-GoveVFn+BSbQPFxYz9AZmhvV+hwJe6M+4YF+yc7sH5Q=";
  };
  tavilyPluginInstall = {
    source = "path";
    sourcePath = "${tavilyPluginSrc}";
    installPath = "${config.home.homeDirectory}/.openclaw/extensions/${tavilyPluginId}";
    version = tavilyPluginVersion;
  };
  managedOpenclawConfig = {
    auth.profiles."openai-codex:default" = {
      provider = "openai-codex";
      mode = "oauth";
    };
    agents.defaults = {
      model.primary = "openai-codex/gpt-5.2-codex";
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
    agents = builtins.removeAttrs managedOpenclawConfig.agents [ "admin" ];
  };
  fixedGateway = upstreamPackages.openclaw-gateway.overrideAttrs (old: {
    pnpmDeps = old.pnpmDeps.overrideAttrs (_: {
      outputHash = "sha256-CDJKsEeDukH6xdLztpeccR6ILxh80BMTMo8McPOSysE=";
    });
    postPatch = (old.postPatch or "") + ''

      # Upstream CLI still bakes the legacy launchd label into daemon constants.
      # Patch the source before bundling so the compiled gateway CLI matches the
      # canonical nix-openclaw launch agent label.
      if [ -f src/daemon/constants.ts ]; then
        perl -0pi -e 's/export const GATEWAY_LAUNCH_AGENT_LABEL = "ai\.openclaw\.gateway";/export const GATEWAY_LAUNCH_AGENT_LABEL = "com.steipete.openclaw.gateway";/' src/daemon/constants.ts
        perl -0pi -e 's/return `ai\.openclaw\.\$\{normalized\}`;/return `com.steipete.openclaw.gateway.\$\{normalized\}`;/' src/daemon/constants.ts
      fi
    '';
    preInstall = (old.preInstall or "") + ''
      # pnpm also vendors an embedded openclaw package in node_modules. Patch
      # that copied package before installPhase moves node_modules into $out.
      find node_modules/.pnpm -path '*/node_modules/openclaw' -type d | while IFS= read -r pkg; do
        chmod -R u+w "$pkg"
        grep -R -l "ai.openclaw.gateway" "$pkg" | while IFS= read -r file; do
          perl -0pi -e "s/ai\\.openclaw\\.gateway/com.steipete.openclaw.gateway/g" "$file"
        done
      done
    '';
    postInstall = (old.postInstall or "") + ''
      # Baileys imports `long` at runtime without declaring it, so pnpm's
      # strict package layout leaves the package-local resolution path empty.
      long_src="$(find "$out/lib/openclaw/node_modules/.pnpm" -path "*/long@*/node_modules/long" -print | head -n 1)"
      baileys_pkg="$(find "$out/lib/openclaw/node_modules/.pnpm" -path "*/node_modules/@whiskeysockets/baileys" -print | head -n 1)"
      openclaw_module_parent="$(find "$out/lib/openclaw/node_modules/.pnpm" -path "*/openclaw@*/node_modules" -print | head -n 1)"

      if [ -n "$long_src" ]; then
        if [ ! -e "$out/lib/openclaw/node_modules/long" ]; then
          ln -s "$long_src" "$out/lib/openclaw/node_modules/long"
        fi

        if [ -n "$baileys_pkg" ] && [ ! -e "$baileys_pkg/node_modules/long" ]; then
          mkdir -p "$baileys_pkg/node_modules"
          ln -s "$long_src" "$baileys_pkg/node_modules/long"
        fi
      fi

      # Scrub the stale gateway label from all installed text artifacts,
      # including the embedded openclaw package copy under node_modules.
      chmod -R u+w "$out/lib/openclaw"
      grep -R -l "ai.openclaw.gateway" "$out/lib/openclaw" | while IFS= read -r file; do
        perl -0pi -e "s/ai\\.openclaw\\.gateway/com.steipete.openclaw.gateway/g" "$file"
      done

      bundled_skills_dir=""
      openclaw_pkg="$(find "$out/lib/openclaw/node_modules/.pnpm" -path "*/openclaw@*/node_modules/openclaw" -print | head -n 1)"
      openclaw_node_modules="$out/lib/openclaw/node_modules"
      if [ -n "$openclaw_pkg" ] && [ -d "$openclaw_pkg/skills" ]; then
        bundled_skills_dir="$openclaw_pkg/skills"
      fi

      wrap_args=()
      if [ -d "$openclaw_node_modules" ]; then
        wrap_args+=(--prefix NODE_PATH : "$openclaw_node_modules")
      fi
      if [ -n "$openclaw_module_parent" ]; then
        wrap_args+=(--prefix NODE_PATH : "$openclaw_module_parent")
      fi
      if [ -n "$bundled_skills_dir" ]; then
        wrap_args+=(--set-default OPENCLAW_BUNDLED_SKILLS_DIR "$bundled_skills_dir")
      fi
      wrap_args+=(
        --set-default http_proxy ${lib.escapeShellArg proxyEnv.http_proxy}
        --set-default https_proxy ${lib.escapeShellArg proxyEnv.https_proxy}
        --set-default all_proxy ${lib.escapeShellArg proxyEnv.all_proxy}
        --set-default HTTP_PROXY ${lib.escapeShellArg proxyEnv.HTTP_PROXY}
        --set-default HTTPS_PROXY ${lib.escapeShellArg proxyEnv.HTTPS_PROXY}
        --set-default ALL_PROXY ${lib.escapeShellArg proxyEnv.ALL_PROXY}
        --set-default no_proxy ${lib.escapeShellArg proxyEnv.no_proxy}
        --set-default NO_PROXY ${lib.escapeShellArg proxyEnv.NO_PROXY}
        --run 'if [ -f "'"${config.home.homeDirectory}"'/.secrets/feishu-app-id" ]; then export FEISHU_APP_ID="$(cat "'"${config.home.homeDirectory}"'/.secrets/feishu-app-id")"; fi'
        --run 'if [ -f "'"${config.home.homeDirectory}"'/.secrets/feishu-app-secret" ]; then export FEISHU_APP_SECRET="$(cat "'"${config.home.homeDirectory}"'/.secrets/feishu-app-secret")"; fi'
        --run 'if [ -f "'"${config.home.homeDirectory}"'/.secrets/jina-api-key" ]; then export JINA_API_KEY="$(cat "'"${config.home.homeDirectory}"'/.secrets/jina-api-key")"; fi'
        --run 'if [ -f "'"${config.home.homeDirectory}"'/.secrets/tavily-api-key" ]; then export TAVILY_API_KEY="$(cat "'"${config.home.homeDirectory}"'/.secrets/tavily-api-key")"; fi'
        --run 'if [ -f "'"${config.home.homeDirectory}"'/.secrets/firecrawl-api-key" ]; then export FIRECRAWL_API_KEY="$(cat "'"${config.home.homeDirectory}"'/.secrets/firecrawl-api-key")"; fi'
      )
      wrapProgram "$out/bin/openclaw" "''${wrap_args[@]}"

    '';
  });
  declarativeOpenclawConfig = pkgs.writeText "openclaw.json" (builtins.toJSON managedOpenclawConfig);
  openclawPackageDir = "$(find ${fixedGateway}/lib/openclaw/node_modules/.pnpm -path '*/openclaw@*/node_modules/openclaw' -print | head -n 1)";
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
  imports = [ nix-openclaw.homeManagerModules.openclaw ];
  home.sessionPath = lib.mkBefore [ "${config.home.homeDirectory}/.local/bin" ];
  home.packages = [ (lib.hiPrio fixedGateway) ];

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
  home.activation.openclawMemoryLancedbProInstall = lib.hm.dag.entryAfter [ "openclawDeclarativeConfigLink" ] ''
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
  home.activation.openclawTavilyInstall = lib.hm.dag.entryAfter [ "openclawMemoryLancedbProInstall" ] ''
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
