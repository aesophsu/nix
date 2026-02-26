{ config, myvars, ... }:

let
  homeDir = config.users.users."${myvars.username}".home;
in
{
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = false;
  };

  launchd.user.agents.gnupg-agent.serviceConfig = {
    StandardErrorPath = "${homeDir}/Library/Logs/gnupg-agent.stderr.log";
    StandardOutPath = "${homeDir}/Library/Logs/gnupg-agent.stdout.log";
  };
}
