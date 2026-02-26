{
  lib,
  mylib,
  myvars,
  system,
  configurations,
  ...
}:
let
  present = builtins.hasAttr "stella" configurations;
  cfg = if present then configurations.stella else null;
  expectedHomeDir = mylib.homeDirForSystem {
    inherit system;
    username = myvars.username;
  };
in
{
  "darwin-stella-present" = present;
  "darwin-stella-hostname" = present && cfg.config.networking.hostName == "stella";
  "darwin-stella-computer-name" = present && cfg.config.networking.computerName == "stella";
  "darwin-stella-localhost-name" = present && cfg.config.networking.localHostName == "stella";
  "darwin-stella-home-manager-option" = present && lib.hasAttrByPath [ "home-manager" "users" ] cfg.options;
  "darwin-stella-home-manager-home-directory" =
    present && cfg.config."home-manager".users.${myvars.username}.home.homeDirectory == expectedHomeDir;
  "darwin-stella-fonts-option" = present && lib.hasAttrByPath [ "modules" "desktop" "fonts" "enable" ] cfg.options;
  "darwin-stella-fonts-enabled" = present && cfg.config.modules.desktop.fonts.enable;
}
