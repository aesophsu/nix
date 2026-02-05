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
        # nix-openclaw overlay（在此注入，避免 modules/darwin/openclaw.nix 依赖 inputs）
        { nixpkgs.overlays = [ inputs.nix-openclaw.overlays.default ]; }
      ];

    home-modules =
      (map mylib.relativeToRoot [
        "hosts/darwin-${name}/home.nix"
        "home/darwin"
      ])
      ++ [ inputs.nix-openclaw.homeManagerModules.openclaw ];
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
