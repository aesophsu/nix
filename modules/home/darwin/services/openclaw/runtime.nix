{
  config,
  lib,
  myvars,
  pkgs,
  ...
}:
let
  inherit (config._module.args.openclawPackage)
    bundledPluginsDir
    bundledSkillsDir
    fixedGateway
    openclawRoot
    upstreamPackages
    ;
  inherit (config._module.args.openclawConfig)
    declarativeOpenclawConfig
    managedOpenclawHmConfig
    ;
  inherit (config._module.args.openclawPlugins)
    memoryLancedbProId
    memoryLancedbProSrc
    memoryLancedbProVersion
    tavilyPluginId
    tavilyPluginSrc
    tavilyPluginVersion
    ;
  inherit (config._module.args.openclawSecrets)
    envFileSource
    wrapperSecretExports
    ;
  proxyEnv = myvars.networking.proxy.env {
    inherit (myvars.networking.mihomo) httpProxy socksProxy;
  };
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
  home.file.".openclaw/.env".source = envFileSource;
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

      ${wrapperSecretExports}

      if [ -z "$OPENCLAW_BUNDLED_SKILLS_DIR" ] && [ -d "${bundledSkillsDir}" ]; then
        export OPENCLAW_BUNDLED_SKILLS_DIR="${bundledSkillsDir}"
      fi
      if [ -z "$OPENCLAW_BUNDLED_PLUGINS_DIR" ] && [ -d "${bundledPluginsDir}" ]; then
        export OPENCLAW_BUNDLED_PLUGINS_DIR="${bundledPluginsDir}"
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
    openclaw_pkg="${openclawRoot}"
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
