{ lib }:

{
  # Back-compat shim: prefer outputs/lib/mk-platform-outputs.nix
  mkPlatformOutput =
    args:
    let
      new = import ./mk-platform-outputs.nix { inherit lib; };
    in
    new.mkPlatformOutputs {
      fragmentDir = args.srcDir or (throw "mkPlatformOutput shim requires srcDir");
      inherit (args) aggregate testsFn;
      args = args.args;
    };
}
