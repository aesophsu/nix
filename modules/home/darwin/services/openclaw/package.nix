{
  config,
  lib,
  myvars,
  nix-openclaw,
  pkgs,
  ...
}:
let
  upstreamPackages = nix-openclaw.packages.${pkgs.stdenv.hostPlatform.system};
  proxyEnv = myvars.networking.proxy.env {
    inherit (myvars.networking.mihomo) httpProxy socksProxy;
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
in
{
  _module.args.openclawPackage = {
    inherit fixedGateway upstreamPackages;
    openclawPackageDir =
      "$(find ${fixedGateway}/lib/openclaw/node_modules/.pnpm -path '*/openclaw@*/node_modules/openclaw' -print | head -n 1)";
  };
}
