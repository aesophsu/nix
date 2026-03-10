{
  nix-openclaw,
  ...
}:
{
  imports = [
    nix-openclaw.homeManagerModules.openclaw
    ./package.nix
    ./plugins.nix
    ./config.nix
    ./secrets.nix
    ./runtime.nix
  ];
}
