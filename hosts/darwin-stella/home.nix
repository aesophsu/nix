{ config, myvars, ... }:

{
  programs.ssh.matchBlocks."github.com".identityFile =
    "${config.home.homeDirectory}/.ssh/${myvars.hostname}";
}
