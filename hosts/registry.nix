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
      enabled = true;
    }

    {
      name = "shaka-manual-installer";
      platform = "nixos";
      system = "x86_64-linux";
      hostPath = "hosts/nixos-shaka-installer";
      kind = "installer";
      roles = [ "installer" ];
      isoPackageAliases = [
        "macbookpro11-2-manual-installer-iso"
        "shaka-manual-installer-iso"
      ];
      enabled = true;
    }

    {
      name = "shaka";
      platform = "nixos";
      system = "x86_64-linux";
      hostPath = "hosts/nixos-shaka";
      roles = [ "desktop" ];
      enabled = true;
    }
  ];
}
