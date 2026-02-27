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
    backup_dir="$config_dir/.backup"
    staging_dir="$config_dir/.staging"
    mirror_dir=${lib.escapeShellArg geodata.mirrorDir}
    mirror_current="$mirror_dir/current"
    status_file="$mirror_dir/last-run.json"
    entries_file="$staging_dir/status-entries.jsonl"
    base_url=${lib.escapeShellArg geodata.baseUrl}
    on_failure=${lib.escapeShellArg geodata.onFailure}
    managed_files=(${managedFilesArgs})
    any_failure=0

    mkdir -p "$config_dir" "$backup_dir" "$staging_dir" "$mirror_current"
    : > "$entries_file"

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

    backup_file_if_exists "$config_dir/config.yaml" "config.yaml"
    for name in "''${managed_files[@]}"; do
      backup_file_if_exists "$config_dir/$name" "$name"
    done

    for name in "''${managed_files[@]}"; do
      url="$base_url/$name"
      tmp="$staging_dir/$name.tmp"
      target="$config_dir/$name"
      backup="$backup_dir/$name.latest"
      mirror_target="$mirror_current/$name"

      mkdir -p "$(dirname "$tmp")" "$(dirname "$target")" "$(dirname "$backup")" "$(dirname "$mirror_target")"

      if ${pkgs.curl}/bin/curl \
        --fail \
        --location \
        --silent \
        --show-error \
        --retry 3 \
        --connect-timeout 10 \
        --max-time 120 \
        --output "$tmp" \
        "$url" && [ -s "$tmp" ]; then
        mv -f "$tmp" "$target"
        cp -f "$target" "$mirror_target"
        echo "[mihomoSafeUpdate] UPDATED $name"
        record_status "$name" "UPDATED" "$url"
      else
        rm -f "$tmp"
        any_failure=1
        if [ -f "$backup" ]; then
          cp -f "$backup" "$target"
          echo "[mihomoSafeUpdate] RESTORED $name"
          record_status "$name" "RESTORED" "backup"
        elif [ -f "$target" ]; then
          echo "[mihomoSafeUpdate] KEPT_OLD $name"
          record_status "$name" "KEPT_OLD" "existing"
        else
          echo "[mihomoSafeUpdate] MISSING $name"
          record_status "$name" "MISSING" "none"
        fi
      fi
    done

    if [ -f "$config_dir/config.yaml" ]; then
      cp -f "$config_dir/config.yaml" "$mirror_current/config.yaml"
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
