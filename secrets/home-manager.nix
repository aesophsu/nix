{ config, lib, agenix, hostRegistry, myvars, ... }@args:
let
  secretsSource = import ./source.nix {
    inputs = lib.optionalAttrs (args ? mysecrets) { mysecrets = args.mysecrets; };
  };
  schema = import ./schema.nix;
  hostMeta =
    if builtins.hasAttr myvars.hostname (hostRegistry.byNameEnabled or { }) then
      hostRegistry.byNameEnabled.${myvars.hostname}
    else
      { };
  secretsEnabled = lib.attrByPath [ "secrets" "enabled" ] false hostMeta;
  profile = lib.attrByPath [ "secrets" "profile" ] null hostMeta;
  hmAgeIdentityPath =
    lib.attrByPath [ "secrets" "hmAgeIdentityPath" ] null hostMeta;
  relPath = lib.attrByPath [ "byProfile" profile "home-manager" "mihomoConfig" ] null schema;
  secretFileCandidate =
    if secretsSource.enabled && secretsEnabled && relPath != null then
      secretsSource.root + "/${relPath}"
    else
      null;
  secretFile = if secretFileCandidate != null && builtins.pathExists secretFileCandidate then secretFileCandidate else null;
in
{
  imports = [ agenix.homeManagerModules.default ];

  age.identityPaths = [
    (if hmAgeIdentityPath != null then hmAgeIdentityPath else "${config.home.homeDirectory}/.ssh/${myvars.hostname}")
  ];

  age.secrets = lib.mkIf (secretFile != null) {
    "mihomo-config" = {
      file = secretFile;
    };
  };
}
