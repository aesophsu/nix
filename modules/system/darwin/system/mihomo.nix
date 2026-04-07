{
  config,
  pkgs,
  myvars,
  ...
}:

let
  homeDir = config.users.users."${myvars.username}".home;
  configDir = "${homeDir}/.config/mihomo";
  providersDir = "${configDir}/proxies";
in
{
  launchd.daemons.mihomo = {
    serviceConfig = {
      Label = "mihomo";
      ProgramArguments = [
        "/bin/sh"
        "-c"
        "mkdir -p '${configDir}' '${providersDir}'; exec '${pkgs.mihomo}/bin/mihomo' -d '${configDir}'"
      ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "${homeDir}/Library/Logs/mihomo.stdout.log";
      StandardErrorPath = "${homeDir}/Library/Logs/mihomo.stderr.log";
    };
  };
}
