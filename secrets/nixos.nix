{ config, lib, agenix, hostRegistry, ... }@args:
let
  secretsSource = import ./source.nix {
    inputs = lib.optionalAttrs (args ? mysecrets) { mysecrets = args.mysecrets; };
  };
  schema = import ./schema.nix;
  hostName = lib.attrByPath [ "networking" "hostName" ] null config;
  hostMeta =
    if builtins.isString hostName && builtins.hasAttr hostName (hostRegistry.byNameEnabled or { }) then
      hostRegistry.byNameEnabled.${hostName}
    else
      { };
  secretsEnabled = lib.attrByPath [ "secrets" "enabled" ] false hostMeta;
  profile = lib.attrByPath [ "secrets" "profile" ] null hostMeta;
  relPath = lib.attrByPath [ "byProfile" profile "nixos" "mihomoConfig" ] null schema;
  secretFileCandidate =
    if secretsSource.enabled && secretsEnabled && relPath != null then
      secretsSource.root + "/${relPath}"
    else
      null;
  secretFile = if secretFileCandidate != null && builtins.pathExists secretFileCandidate then secretFileCandidate else null;
in
{
  imports = [ agenix.nixosModules.default ];

  age.identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  age.secrets = lib.mkIf (secretFile != null) {
    "shaka-mihomo-config" = {
      file = secretFile;
      path = "/run/agenix/shaka-mihomo-config.yaml";
      mode = "0400";
      owner = "root";
      group = "root";
    };
  };
}
