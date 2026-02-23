{
  lib,
  mylib,
  hostRegistry,
  myvars,
  system,
  configurations,
  ...
}:
let
  hostLib = mylib.hostRegistry;
  expectedHomeDir = mylib.homeDirForSystem {
    inherit system;
    username = myvars.username;
  };
  hostsForSystem = hostLib.hostsForPlatformSystem hostRegistry "darwin" system;
in
hostLib.mkPerHostTests {
  hosts = hostsForSystem;
  inherit configurations;
  prefix = "darwin";
  buildTests =
    {
      host,
      present,
      cfg,
      testPrefix,
    }:
    {
      "${testPrefix}-present" = present;
      "${testPrefix}-hostname" = present && cfg.config.networking.hostName == host.name;
      "${testPrefix}-computer-name" = present && cfg.config.networking.computerName == host.name;
      "${testPrefix}-localhost-name" = present && cfg.config.networking.localHostName == host.name;
      "${testPrefix}-home-manager-option" = present && lib.hasAttrByPath [ "home-manager" "users" ] cfg.options;
      "${testPrefix}-home-manager-home-directory" =
        present && cfg.config."home-manager".users.${myvars.username}.home.homeDirectory == expectedHomeDir;
      "${testPrefix}-fonts-option" = present && lib.hasAttrByPath [ "modules" "desktop" "fonts" "enable" ] cfg.options;
      "${testPrefix}-fonts-enabled" = present && cfg.config.modules.desktop.fonts.enable;
    };
}
