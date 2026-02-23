{
  lib,
  ...
}@args:
let
  platformOutputLib = import ../lib/mk-platform-outputs.nix { inherit lib; };

in
platformOutputLib.mkPlatformOutputs {
  inherit args;
  fragmentDir = ./fragments;
  aggregate = fragments: {
    darwinConfigurations = lib.attrsets.mergeAttrsList (
      map (it: it.darwinConfigurations or { }) fragments
    );
  };
  testsFn = outputs: import ./tests (args // { configurations = outputs.darwinConfigurations; });
}
