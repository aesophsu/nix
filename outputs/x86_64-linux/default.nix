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
    nixosConfigurations = lib.attrsets.mergeAttrsList (
      map (it: it.nixosConfigurations or { }) fragments
    );
    packages = lib.attrsets.mergeAttrsList (
      map (it: it.packages or { }) fragments
    );
  };
  testsFn = outputs: import ./tests (args // { configurations = outputs.nixosConfigurations; });
}
