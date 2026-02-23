{
  lib,
  mylib,
  hostRegistry,
  system,
  configurations,
  ...
}:
let
  hostLib = mylib.hostRegistry;
  hostsForSystem = hostLib.hostsForPlatformSystem hostRegistry "nixos" system;
in
hostLib.mkPerHostTests {
  hosts = hostsForSystem;
  inherit configurations;
  prefix = "nixos";
  buildTests =
    {
      host,
      present,
      cfg,
      testPrefix,
    }:
    let
      isInstaller = hostLib.isInstallerHost host;
    in
    {
      "${testPrefix}-present" = present;
      "${testPrefix}-system-matches" = host.system == system;
      "${testPrefix}-hostname" = present && cfg.config.networking.hostName == host.name;
      "${testPrefix}-networking-hostname-option" = present && lib.hasAttrByPath [ "networking" "hostName" ] cfg.options;
      "${testPrefix}-stateVersion-option" = present && lib.hasAttrByPath [ "system" "stateVersion" ] cfg.options;
      "${testPrefix}-iso-image-accessible" =
        if isInstaller then
          present && cfg.config.system.build.isoImage != null
        else
          true;
    }
    // lib.optionalAttrs (!isInstaller) {
      "${testPrefix}-home-manager-option" = present && lib.hasAttrByPath [ "home-manager" "users" ] cfg.options;
      "${testPrefix}-networkmanager-option" = present && lib.hasAttrByPath [ "networking" "networkmanager" "enable" ] cfg.options;
    };
}
