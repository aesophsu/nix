{
  description = "Bootstrap NixOS manual installer ISO for MacBookPro11,2 (shaka)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    rootSrc = {
      url = "path:..";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, rootSrc, ... }:
    let
      system = "x86_64-linux";
      lib = nixpkgs.lib;
      pkgs = nixpkgs.legacyPackages.${system};

      installerConfig = lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit rootSrc;
        };
        modules = [
          "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
          ./hosts/shaka-mbp112-installer.nix
        ];
      };

      smokeEval = pkgs.runCommand "smoke-eval" { } ''
        ${if installerConfig.config.system.build.isoImage != null then "touch $out" else "exit 1"}
      '';
    in
    {
      nixosConfigurations.shaka-mbp112-installer = installerConfig;

      packages.${system} = {
        shaka-manual-installer-iso = installerConfig.config.system.build.isoImage;
        default = installerConfig.config.system.build.isoImage;
      };

      checks.${system} = {
        smoke-eval = smokeEval;
      };
    };
}
