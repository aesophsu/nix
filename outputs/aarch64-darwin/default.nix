{
  lib,
  inputs,
  ...
}@args:
let
  inherit (inputs) haumea;

  # =====================================================================================
  # Load all darwin system fragments under ./src
  # =====================================================================================

  data = haumea.lib.load {
    src = ./src;
    inputs = args;
  };

  dataWithoutPaths = builtins.attrValues data;

  # =====================================================================================
  # Aggregate darwin outputs
  # =====================================================================================

  outputs = {
    darwinConfigurations = lib.attrsets.mergeAttrsList (
      map (it: it.darwinConfigurations or { }) dataWithoutPaths
    );
  };

in
outputs
// {
  # =====================================================================================
  # Debug & evaluation
  # =====================================================================================

  inherit data;

  # No eval tests yet; return empty attrset
  evalTests = { };
}
