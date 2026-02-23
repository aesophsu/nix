{ lib }:

{
  mkPlatformOutputs =
    {
      fragmentDir,
      args,
      aggregate,
      testsFn,
    }:
    let
      fragmentImports = args.mylib.discoverImports { dir = fragmentDir; };
      fragments = map (fragmentPath: import fragmentPath args) fragmentImports;
      outputs = aggregate fragments;
      evalTests = testsFn outputs;
    in
    outputs
    // {
      data = fragments;
      inherit evalTests;
    };
}
