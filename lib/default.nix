{ lib, ... }:

{
  macosSystem = import ./macosSystem.nix;

  # Build path relative to flake root: relativeToRoot "modules/darwin" => /path/to/flake/modules/darwin
  relativeToRoot = lib.path.append ../.;
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
}
