{ inputs, mylib, myvars, shaka, system, ... }:
{
  imports = [ inputs.home-manager.nixosModules.home-manager ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit mylib myvars system;
    };
    users.${shaka.username}.imports = [ ../../../../home/nixos/shaka ];
  };
}
