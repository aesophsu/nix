{ lib }:
let
  parts = [
    (import ./proxy.nix { inherit lib; })
    (import ./mihomo.nix)
    (import ./dns.nix)
    (import ./hosts.nix { inherit lib; })
    (import ./ssh.nix)
  ];
in
lib.foldl' lib.recursiveUpdate { } parts
