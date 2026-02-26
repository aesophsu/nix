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
  ];
}
