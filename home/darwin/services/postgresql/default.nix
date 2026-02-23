# PostgreSQL 16: Nix package, data dir, and launchd service

{ config, pkgs, lib, myvars, ... }:

let
  pg = pkgs.postgresql_16;
  pgData = "${config.xdg.dataHome}/postgresql/16";
  pgLog = "${config.xdg.dataHome}/postgresql/16.log";
in
{
  home.packages = [ pg ];

  # First deploy: run initdb if data dir does not exist
  home.activation.initPostgres = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -f "${pgData}/PG_VERSION" ]; then
      echo "Initializing PostgreSQL data directory at ${pgData}..."
      mkdir -p "$(dirname ${pgData})"
      ${pg}/bin/initdb -D "${pgData}" -E UTF8
      echo "PostgreSQL initialized. Start with: launchctl kickstart -k gui/$(id -u)/org.nix.postgresql"
    fi
  '';

  # launchd: start on login, restart on crash
  launchd.agents."org.nix.postgresql" = {
    enable = true;
    config = {
      Label = "org.nix.postgresql";
      # Run postgres directly (Nixpkgs pg_ctl has no "run" subcommand)
      ProgramArguments = [
        "${pg}/bin/postgres"
        "-D"
        pgData
      ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = pgLog;
      StandardErrorPath = pgLog;
      WorkingDirectory = config.home.homeDirectory;
    };
  };
}
