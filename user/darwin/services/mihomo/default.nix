# mihomo: package, env vars, config, launchd
# Config precedence: config.local.yaml > config.yaml > config.yaml.example

{ config, pkgs, lib, mylib, myvars, ... }:

let
  configDir = "${config.xdg.configHome}/mihomo";
  configSource = mylib.firstExistingPathOr {
    candidates = [
      ./config.local.yaml
      ./config.yaml
    ];
    default = ./config.yaml.example;
  };
  inherit (myvars.networking.mihomo) httpProxy socksProxy;
  proxyEnv = myvars.networking.proxy.env { inherit httpProxy socksProxy; };
  geodata = myvars.networking.mihomo.geodata;
  managedFilesArgs = lib.concatStringsSep " " (map lib.escapeShellArg geodata.managedFiles);
in
{
  home.packages = [ pkgs.mihomo ];

  # Env vars so CLI (curl, wget, git, etc.) use mihomo proxy
  # no_proxy includes mirror domains so pip/uv/brew can go direct
  home.sessionVariables = proxyEnv;

  xdg.configFile."mihomo/config.yaml" = {
    source = configSource;
  };

  home.activation.mihomoSafeUpdate = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    set -u

    config_dir=${lib.escapeShellArg configDir}
    config_file="$config_dir/config.yaml"
    backup_dir="$config_dir/.backup"
    staging_dir="$config_dir/.staging"
    mirror_dir=${lib.escapeShellArg geodata.mirrorDir}
    mirror_current="$mirror_dir/current"
    status_file="$mirror_dir/last-run.json"
    entries_file="$staging_dir/status-entries.jsonl"
    download_list="$staging_dir/download-list.tsv"
    seen_paths="$staging_dir/seen-paths.txt"
    base_url=${lib.escapeShellArg geodata.baseUrl}
    on_failure=${lib.escapeShellArg geodata.onFailure}
    managed_files=(${managedFilesArgs})
    any_failure=0

    rm -rf "$mirror_current"
    mkdir -p "$config_dir" "$backup_dir" "$staging_dir" "$mirror_current" "$mirror_current/rules"
    : > "$entries_file"
    : > "$download_list"
    : > "$seen_paths"

    record_status() {
      file="$1"
      status="$2"
      source="$3"
      printf '    {"file":"%s","status":"%s","source":"%s"}\n' "$file" "$status" "$source" >> "$entries_file"
    }

    backup_file_if_exists() {
      src="$1"
      name="$2"
      backup="$backup_dir/$name.latest"
      if [ -f "$src" ]; then
        mkdir -p "$(dirname "$backup")"
        cp -f "$src" "$backup"
      fi
    }

    normalize_path() {
      rel="$1"
      rel="''${rel#./}"
      rel="''${rel#/}"
      printf '%s' "$rel"
    }

    add_download() {
      raw_path="$1"
      url="$2"
      rel_path="$(normalize_path "$raw_path")"
      if [ -z "$rel_path" ] || [ -z "$url" ]; then
        return
      fi
      if grep -Fqx "$rel_path" "$seen_paths"; then
        return
      fi
      printf '%s\n' "$rel_path" >> "$seen_paths"
      printf '%s\t%s\n' "$rel_path" "$url" >> "$download_list"
    }

    fallback_url_for_path() {
      rel_path="$1"
      base_name="$(basename "$rel_path")"
      case "$base_name" in
        Country.mmdb|country.mmdb)
          printf '%s' "$base_url/country.mmdb"
          ;;
        GeoLite2-ASN.mmdb)
          printf '%s' "$base_url/GeoLite2-ASN.mmdb"
          ;;
        geosite.dat)
          printf '%s' "$base_url/geosite.dat"
          ;;
        geoip.dat)
          printf '%s' "$base_url/geoip.dat"
          ;;
        geoip.metadb)
          printf '%s' "$base_url/geoip.metadb"
          ;;
        *)
          printf ""
          ;;
      esac
    }

    if [ -f "$config_file" ]; then
      add_download \
        "$(${pkgs.yq-go}/bin/yq -r '.geox.geoip.path // ""' "$config_file" 2>/dev/null || true)" \
        "$(${pkgs.yq-go}/bin/yq -r '.geox.geoip.url // ""' "$config_file" 2>/dev/null || true)"
      add_download \
        "$(${pkgs.yq-go}/bin/yq -r '.geox.geoip["asn-path"] // ""' "$config_file" 2>/dev/null || true)" \
        "$(${pkgs.yq-go}/bin/yq -r '.geox.geoip["asn-url"] // ""' "$config_file" 2>/dev/null || true)"
      add_download \
        "$(${pkgs.yq-go}/bin/yq -r '.geox.geosite.path // ""' "$config_file" 2>/dev/null || true)" \
        "$(${pkgs.yq-go}/bin/yq -r '.geox.geosite.url // ""' "$config_file" 2>/dev/null || true)"

      while IFS=$'\t' read -r p u; do
        [ -n "$p" ] && [ -n "$u" ] && add_download "$p" "$u"
      done <<EOF
$(${pkgs.yq-go}/bin/yq -r '.["rule-providers"] // {} | to_entries[] | select((.value.type // "") == "http") | [.value.path // "", .value.url // ""] | @tsv' "$config_file" 2>/dev/null || true)
EOF

    fi

    if [ ! -s "$download_list" ]; then
      for name in "''${managed_files[@]}"; do
        add_download "$name" "$base_url/$name"
      done
    fi

    backup_file_if_exists "$config_file" "config.yaml"

    while IFS=$'\t' read -r rel_path _; do
      [ -n "$rel_path" ] || continue
      backup_file_if_exists "$config_dir/$rel_path" "$rel_path"
    done < "$download_list"

    while IFS=$'\t' read -r rel_path url; do
      [ -n "$rel_path" ] || continue
      [ -n "$url" ] || continue
      tmp="$staging_dir/$rel_path.tmp"
      target="$config_dir/$rel_path"
      backup="$backup_dir/$rel_path.latest"
      mirror_target="$mirror_current/$rel_path"
      source_url="$url"
      fallback_url="$(fallback_url_for_path "$rel_path")"

      mkdir -p "$(dirname "$tmp")" "$(dirname "$target")" "$(dirname "$backup")" "$(dirname "$mirror_target")"

      if ! ${pkgs.curl}/bin/curl \
        --fail \
        --location \
        --silent \
        --show-error \
        --retry 3 \
        --connect-timeout 10 \
        --max-time 120 \
        --output "$tmp" \
        "$source_url"; then
        rm -f "$tmp"
        if [ -n "$fallback_url" ] && [ "$fallback_url" != "$source_url" ]; then
          source_url="$fallback_url"
          ${pkgs.curl}/bin/curl \
            --fail \
            --location \
            --silent \
            --show-error \
            --retry 3 \
            --connect-timeout 10 \
            --max-time 120 \
            --output "$tmp" \
            "$source_url" || true
        fi
      fi

      if [ -s "$tmp" ]; then
        mv -f "$tmp" "$target"
        cp -f "$target" "$mirror_target"
        echo "[mihomoSafeUpdate] UPDATED $rel_path"
        record_status "$rel_path" "UPDATED" "$source_url"
      else
        rm -f "$tmp"
        any_failure=1
        if [ -f "$backup" ]; then
          cp -f "$backup" "$target"
          echo "[mihomoSafeUpdate] RESTORED $rel_path"
          record_status "$rel_path" "RESTORED" "backup"
        elif [ -f "$target" ]; then
          echo "[mihomoSafeUpdate] KEPT_OLD $rel_path"
          record_status "$rel_path" "KEPT_OLD" "existing"
        else
          echo "[mihomoSafeUpdate] MISSING $rel_path"
          record_status "$rel_path" "MISSING" "none"
        fi
      fi
    done < "$download_list"

    if [ -f "$config_file" ]; then
      cp -f "$config_file" "$mirror_current/config.yaml"
    fi

    json_files="$(${pkgs.gawk}/bin/awk '
      NR == 1 { printf "%s", $0; next }
      { printf ",\n%s", $0 }
      END {
        if (NR == 0) {
          printf ""
        }
      }
    ' "$entries_file")"
    timestamp="$(${pkgs.coreutils}/bin/date -u +"%Y-%m-%dT%H:%M:%SZ")"

    cat > "$status_file" <<EOF
{
  "timestamp":"$timestamp",
  "baseUrl":"$base_url",
  "onFailure":"$on_failure",
  "files":[
$json_files
  ]
}
EOF

    if [ "$any_failure" -eq 1 ] && [ "$on_failure" = "strict-fail" ]; then
      echo "[mihomoSafeUpdate] strict-fail enabled, aborting activation."
      exit 1
    fi
  '';

  launchd.agents.mihomo = {
    enable = true;
    config = {
      Label = "mihomo";
      ProgramArguments = [
        "${pkgs.mihomo}/bin/mihomo"
        "-d"
        configDir
      ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/mihomo.stdout.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/mihomo.stderr.log";
    };
  };
}
