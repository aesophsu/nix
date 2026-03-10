{ lib }:
let
  identity = import ./identity.nix;
in
identity
// {
  networking = import ./networking { inherit lib; };
  toolchains = import ./toolchains.nix;
}
