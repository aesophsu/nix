{ config, pkgs, myvars, ... }:

let
  homeDir = config.users.users."${myvars.username}".home;
  maintenanceScript = pkgs.writeShellScript "nix-store-maintenance" ''
    set -euo pipefail

    export PATH="/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"

    echo "[$(/bin/date '+%F %T')] nix store maintenance start"
    if command -v nix-collect-garbage >/dev/null 2>&1; then
      nix-collect-garbage -d
    else
      nix store gc
    fi

    if command -v nix >/dev/null 2>&1; then
      nix store optimise || true
    fi
    echo "[$(/bin/date '+%F %T')] nix store maintenance done"
  '';
in
{
  # Determinate Nix manages the daemon; use a user launchd agent for periodic cleanup.
  launchd.user.agents.nix-store-maintenance = {
    serviceConfig = {
      Label = "org.nix.store-maintenance";
      ProgramArguments = [
        "${pkgs.bash}/bin/bash"
        "-lc"
        "${maintenanceScript} >> ${homeDir}/Library/Logs/nix-store-maintenance.log 2>&1"
      ];
      StartCalendarInterval = [
        {
          Weekday = 7; # Sunday
          Hour = 4;
          Minute = 30;
        }
      ];
      ProcessType = "Background";
      Nice = 1;
      StandardOutPath = "${homeDir}/Library/Logs/nix-store-maintenance.stdout.log";
      StandardErrorPath = "${homeDir}/Library/Logs/nix-store-maintenance.stderr.log";
    };
  };
}
