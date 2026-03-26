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
  # Keep this override narrowly scoped so it is easy to drop once
  # nix-openclaw ships the same upstream release and packaging fixes.
  openclawRoot = "${fixedGateway}/lib/openclaw";
  bundledSkillsDir = "${openclawRoot}/node_modules/skillflag/skills";
  bundledPluginsDir = "${openclawRoot}/extensions";
  latestOpenclawSourceInfo = {
    owner = "openclaw";
    repo = "openclaw";
    rev = "cff6dc94e30794a269eb7805b6e636c3634a088c";
    hash = "sha256-cvRoCPf63ocTVgZ38qDW/oZDKXvAwhtvURcQLI9qRMY=";
    pnpmDepsHash = "sha256-UsDwR66NJV+45ar0/5mZoi1v9IQAiG6kxa4RmorQ7h8=";
  };
  proxyEnv = myvars.networking.proxy.env {
    inherit (myvars.networking.mihomo) httpProxy socksProxy;
  };
  fixedGateway = (upstreamPackages.openclaw-gateway.override {
    sourceInfo = latestOpenclawSourceInfo;
    pnpmDepsHash = latestOpenclawSourceInfo.pnpmDepsHash;
  }).overrideAttrs (old: {
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
        grep -R -l "ai.openclaw.gateway" "$pkg" 2>/dev/null | while IFS= read -r file; do
          perl -0pi -e "s/ai\\.openclaw\\.gateway/com.steipete.openclaw.gateway/g" "$file"
        done || true
      done
    '';
    installPhase = ''
      log_step() {
        if [ "''${OPENCLAW_NIX_TIMINGS:-1}" != "1" ]; then
          "$@"
          return
        fi

        name="$1"
        shift

        start=$(date +%s)
        printf '>> [timing] %s...\n' "$name" >&2
        "$@"
        end=$(date +%s)
        printf '>> [timing] %s: %ss\n' "$name" "$((end - start))" >&2
      }

      check_no_broken_symlinks() {
        root="$1"
        if [ ! -d "$root" ]; then
          return 0
        fi

        broken_tmp="$(mktemp)"
        find "$root" -type l -print | while IFS= read -r link; do
          [ -e "$link" ] || printf '%s\n' "$link"
        done > "$broken_tmp"
        if [ -s "$broken_tmp" ]; then
          echo "dangling symlinks found under $root" >&2
          cat "$broken_tmp" >&2
          rm -f "$broken_tmp"
          return 1
        fi
        rm -f "$broken_tmp"
      }

      mkdir -p "$out/lib/openclaw" "$out/bin"

      log_step "move build outputs" mv dist node_modules package.json "$out/lib/openclaw/"
      if [ -d extensions ]; then
        log_step "copy extensions" cp -r extensions "$out/lib/openclaw/"
      fi

      if [ -d docs/reference/templates ]; then
        mkdir -p "$out/lib/openclaw/docs/reference"
        log_step "copy reference templates" cp -r docs/reference/templates "$out/lib/openclaw/docs/reference/"
      fi

      if [ -z "''${STDENV_SETUP:-}" ]; then
        echo "STDENV_SETUP is not set" >&2
        exit 1
      fi
      if [ ! -f "$STDENV_SETUP" ]; then
        echo "STDENV_SETUP not found: $STDENV_SETUP" >&2
        exit 1
      fi

      log_step "patchShebangs node_modules/.bin" bash -e -c '. "$STDENV_SETUP"; patchShebangs "$out/lib/openclaw/node_modules/.bin"'

      # Work around missing dependency declaration in pi-coding-agent (strip-ansi).
      pi_pkg="$(find "$out/lib/openclaw/node_modules/.pnpm" -path "*/node_modules/@mariozechner/pi-coding-agent" -print | head -n 1)"
      strip_ansi_src="$(find "$out/lib/openclaw/node_modules/.pnpm" -path "*/node_modules/strip-ansi" -print | head -n 1)"

      if [ -n "$strip_ansi_src" ]; then
        if [ -n "$pi_pkg" ] && [ ! -e "$pi_pkg/node_modules/strip-ansi" ]; then
          mkdir -p "$pi_pkg/node_modules"
          ln -s "$strip_ansi_src" "$pi_pkg/node_modules/strip-ansi"
        fi

        if [ ! -e "$out/lib/openclaw/node_modules/strip-ansi" ]; then
          mkdir -p "$out/lib/openclaw/node_modules"
          ln -s "$strip_ansi_src" "$out/lib/openclaw/node_modules/strip-ansi"
        fi
      fi

      if [ -n "''${PATCH_CLIPBOARD_SH:-}" ]; then
        "$PATCH_CLIPBOARD_SH" "$out/lib/openclaw" "$PATCH_CLIPBOARD_WRAPPER"
      fi

      # Work around missing combined-stream dependency for form-data in pnpm layout.
      combined_stream_src="$(find "$out/lib/openclaw/node_modules/.pnpm" -path "*/combined-stream@*/node_modules/combined-stream" -print | head -n 1)"
      form_data_pkgs="$(find "$out/lib/openclaw/node_modules/.pnpm" -path "*/node_modules/form-data" -print)"
      if [ -n "$combined_stream_src" ]; then
        if [ ! -e "$out/lib/openclaw/node_modules/combined-stream" ]; then
          ln -s "$combined_stream_src" "$out/lib/openclaw/node_modules/combined-stream"
        fi
        if [ -n "$form_data_pkgs" ]; then
          for pkg in $form_data_pkgs; do
            if [ ! -e "$pkg/node_modules/combined-stream" ]; then
              mkdir -p "$pkg/node_modules"
              ln -s "$combined_stream_src" "$pkg/node_modules/combined-stream"
            fi
          done
        fi
      fi

      # Work around missing hasown dependency for form-data in pnpm layout.
      hasown_src="$(find "$out/lib/openclaw/node_modules/.pnpm" -path "*/hasown@*/node_modules/hasown" -print | head -n 1)"
      if [ -n "$hasown_src" ]; then
        if [ ! -e "$out/lib/openclaw/node_modules/hasown" ]; then
          ln -s "$hasown_src" "$out/lib/openclaw/node_modules/hasown"
        fi
        if [ -n "$form_data_pkgs" ]; then
          for pkg in $form_data_pkgs; do
            if [ ! -e "$pkg/node_modules/hasown" ]; then
              mkdir -p "$pkg/node_modules"
              ln -s "$hasown_src" "$pkg/node_modules/hasown"
            fi
          done
        fi
      fi

      # Baileys imports `long` at runtime without declaring it, so pnpm's
      # strict package layout leaves the package-local resolution path empty.
      long_src="$(find "$out/lib/openclaw/node_modules/.pnpm" -path "*/long@*/node_modules/long" -print | head -n 1)"
      baileys_pkg="$(find "$out/lib/openclaw/node_modules/.pnpm" -path "*/node_modules/@whiskeysockets/baileys" -print | head -n 1)"
      if [ -n "$long_src" ]; then
        if [ ! -e "$out/lib/openclaw/node_modules/long" ]; then
          ln -s "$long_src" "$out/lib/openclaw/node_modules/long"
        fi

        if [ -n "$baileys_pkg" ] && [ ! -e "$baileys_pkg/node_modules/long" ]; then
          mkdir -p "$baileys_pkg/node_modules"
          ln -s "$long_src" "$baileys_pkg/node_modules/long"
        fi
      fi

      # `cmake-js` and `node-llama-cpp` ship `.bin/node-which` wrappers that
      # assume a package-local `which` symlink which pnpm does not materialize.
      which_src="$out/lib/openclaw/node_modules/which"
      cmake_js_pkg="$out/lib/openclaw/node_modules/cmake-js"
      llama_cpp_pkg="$out/lib/openclaw/node_modules/node-llama-cpp"
      if [ -d "$which_src" ]; then
        for pkg in "$cmake_js_pkg" "$llama_cpp_pkg"; do
          if [ -n "$pkg" ] && [ ! -e "$pkg/node_modules/which" ]; then
            mkdir -p "$pkg/node_modules"
            ln -s "$which_src" "$pkg/node_modules/which"
          fi
        done
      fi

      log_step "validate node_modules symlinks" check_no_broken_symlinks "$out/lib/openclaw/node_modules"

      bash -e -c '. "$STDENV_SETUP"; makeWrapper "$NODE_BIN" "$out/bin/openclaw" --add-flags "$out/lib/openclaw/dist/index.js" --set-default OPENCLAW_NIX_MODE "1"'

      openclaw_module_parent="$(find "$out/lib/openclaw/node_modules/.pnpm" -path "*/openclaw@*/node_modules" -print | head -n 1)"

      # Scrub the stale gateway label from all installed text artifacts,
      # including the embedded openclaw package copy under node_modules.
      chmod -R u+w "$out/lib/openclaw"
      # OpenClaw discovers bundled plugins from the installed extensions tree,
      # so normalize the package names in the final output it actually scans.
      rewrite_plugin_name() {
        plugin_json="$1"
        plugin_name="$2"
        tmp_json="$(mktemp)"
        ${lib.getExe pkgs.jq} --arg plugin_name "$plugin_name" \
          '.name = $plugin_name' "$plugin_json" > "$tmp_json"
        mv "$tmp_json" "$plugin_json"
      }
      rewrite_plugin_name "$out/lib/openclaw/extensions/elevenlabs/package.json" "@openclaw/elevenlabs"
      rewrite_plugin_name "$out/lib/openclaw/extensions/microsoft/package.json" "@openclaw/microsoft"
      grep -R -l "ai.openclaw.gateway" "$out/lib/openclaw" 2>/dev/null | while IFS= read -r file; do
        perl -0pi -e "s/ai\\.openclaw\\.gateway/com.steipete.openclaw.gateway/g" "$file"
      done || true

      bundled_skills_dir=""
      bundled_plugins_dir=""
      openclaw_pkg="$(find "$out/lib/openclaw/node_modules/.pnpm" -path "*/openclaw@*/node_modules/openclaw" -print | head -n 1)"
      openclaw_node_modules="$out/lib/openclaw/node_modules"
      if [ -n "$openclaw_pkg" ] && [ -d "$openclaw_pkg/skills" ]; then
        bundled_skills_dir="$openclaw_pkg/skills"
      fi
      if [ -d "$out/lib/openclaw/extensions" ]; then
        bundled_plugins_dir="$out/lib/openclaw/extensions"
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
      if [ -n "$bundled_plugins_dir" ]; then
        wrap_args+=(--set-default OPENCLAW_BUNDLED_PLUGINS_DIR "$bundled_plugins_dir")
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
    inherit openclawRoot bundledSkillsDir bundledPluginsDir;
  };
}
