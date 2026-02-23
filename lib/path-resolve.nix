{ lib }:

let
  firstExistingPath =
    candidates:
    let
      filtered = builtins.filter builtins.pathExists candidates;
    in
    if filtered == [ ] then null else builtins.head filtered;

  firstExistingPathOr =
    {
      candidates,
      default,
    }:
    let
      hit = firstExistingPath candidates;
    in
    if hit == null then default else hit;

  homeDirForSystem =
    {
      system,
      username,
    }:
    if lib.hasSuffix "-darwin" system then
      "/Users/${username}"
    else if lib.hasSuffix "-linux" system then
      "/home/${username}"
    else
      throw "homeDirForSystem: unsupported system '${system}'";
in
{
  inherit firstExistingPath firstExistingPathOr homeDirForSystem;
}
