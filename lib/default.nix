{ lib, ... }:

let
  pathResolve = import ./path-resolve.nix { inherit lib; };
  moduleDiscovery = import ./module-discovery.nix { inherit lib; };
  hostRegistry = import ./host-registry.nix { inherit lib; };
in
{
  macosSystem = import ./macosSystem.nix;

  # Build path relative to flake root: relativeToRoot "modules/darwin" => /path/to/flake/modules/darwin
  relativeToRoot = lib.path.append ../.;

  # Legacy primitive kept for compatibility; prefer discoverImports/discoverModulesOnly.
  scanPaths =
    path:
    builtins.map (name: (path + "/${name}")) (
      builtins.attrNames (
        lib.attrsets.filterAttrs (
          name: type:
          (type == "directory") || ((name != "default.nix") && (lib.strings.hasSuffix ".nix" name))
        ) (builtins.readDir path)
      )
    );

  inherit (moduleDiscovery)
    discoverImports
    discoverModulesOnly
    ;

  inherit (pathResolve)
    firstExistingPath
    firstExistingPathOr
    homeDirForSystem
    ;

  hostRegistry = hostRegistry;
}
