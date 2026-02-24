{ myvars, ... }:

let
  darwinPrimary = myvars.hostname;
in
{
  # Pure host data. Validation/indexing lives in lib/host-registry.nix.
  hosts = [
    {
      name = darwinPrimary;
      platform = "darwin";
      system = "aarch64-darwin";
      hostPath = "hosts/darwin-${darwinPrimary}";
      roles = [ "desktop" ];
      tags = [
        "primary"
        "macbook-air-m4"
      ];
      deploy = {
        method = "darwin-rebuild";
        target = "local";
      };
      secrets = {
        enabled = true;
        profile = "darwin-stella";
        hmAgeIdentityPath = "/Users/${myvars.username}/.ssh/${darwinPrimary}";
      };
      enabled = true;
    }

    {
      name = "shaka";
      platform = "nixos";
      system = "x86_64-linux";
      hostPath = "hosts/nixos-shaka";
      roles = [ "desktop" ];
      deploy = {
        method = "manual-installer";
        target = "local";
      };
      secrets = {
        enabled = true;
        profile = "nixos-shaka";
      };
      bootstrap = {
        installerFlake = "nixos-installer";
        installerProfile = "shaka-manual-installer-iso";
      };
      enabled = true;
    }
  ];
}
