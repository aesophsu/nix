{ inputs, myvars, shaka, ... }:
{
  imports = [ inputs.home-manager.nixosModules.home-manager ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit myvars; };
    users.${shaka.username}.imports = [ ../../../../home/nixos/shaka ];
  };
}
