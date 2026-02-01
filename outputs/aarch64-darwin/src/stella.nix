{
  inputs,
  lib,
  mylib,
  myvars,
  system,
  genSpecialArgs,
  ...
}@args:
let
  name = myvars.hostname;

  # =====================================================================================
  # Module composition
  # =====================================================================================

  modules = {
    darwin-modules =
      (map mylib.relativeToRoot [
        # "secrets/darwin.nix"
        "modules/darwin"
        "hosts/darwin-${name}"
      ])
      ++ [
        {
          modules.desktop.fonts.enable = true;
        }
      ];

    home-modules = map mylib.relativeToRoot [
      "hosts/darwin-${name}/home.nix"
      "home/darwin"
    ];
  };

  # =====================================================================================
  # System arguments
  # =====================================================================================

  systemArgs = modules // args;

in
{
  # =====================================================================================
  # macOS host entry
  # =====================================================================================

  darwinConfigurations.${name} = mylib.macosSystem systemArgs;
}
