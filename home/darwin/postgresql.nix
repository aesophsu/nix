{ config, pkgs, lib, myvars, ... }:

let
  pg = pkgs.postgresql_16;
  pgData = "${config.xdg.dataHome}/postgresql/16";
  pgLog = "${config.xdg.dataHome}/postgresql/16.log";
in
{
  home.packages = [ pg ];

  # 首次部署：若数据目录不存在则执行 initdb
  home.activation.initPostgres = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -f "${pgData}/PG_VERSION" ]; then
      echo "Initializing PostgreSQL data directory at ${pgData}..."
      mkdir -p "$(dirname ${pgData})"
      ${pg}/bin/initdb -D "${pgData}" -E UTF8
      echo "PostgreSQL initialized. Start with: launchctl kickstart -k gui/$(id -u)/org.nix.postgresql"
    fi
  '';

  # launchd 服务：开机自启，崩溃自动重启
  launchd.agents."org.nix.postgresql" = {
    enable = true;
    config = {
      Label = "org.nix.postgresql";
      ProgramArguments = [
        "${pg}/bin/pg_ctl"
        "-D"
        pgData
        "-l"
        pgLog
        "-w"
        "run"
      ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = pgLog;
      StandardErrorPath = pgLog;
      WorkingDirectory = config.home.homeDirectory;
    };
  };
}
