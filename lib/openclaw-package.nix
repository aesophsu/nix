# OpenClaw build + PATH-safe wrapper (exclude oracle; openclaw* bins only). Used by genSpecialArgs.

{ pkgs
, nix-openclaw
, nix-steipete-tools
, system
}:

let
  fullOpenclaw = (import (nix-openclaw + "/nix/packages") {
    inherit pkgs;
    sourceInfo = import (nix-openclaw + "/nix/sources/openclaw-source.nix");
    steipetePkgs = nix-steipete-tools.packages.${system} or { };
    excludeToolNames = [ "oracle" ];
  }).openclaw;

  openclawPackageNoOracle = pkgs.runCommand "openclaw-path-safe"
    { passthru = fullOpenclaw.passthru or { }; }
    ''
      mkdir -p $out/bin
      for x in ${fullOpenclaw}/bin/*; do
        n=$(basename "$x")
        case "$n" in
          openclaw*) ln -s "$x" $out/bin/ ;;
          *) : ;;
        esac
      done
      for d in lib share Applications; do
        [ -e ${fullOpenclaw}/$d ] && ln -s ${fullOpenclaw}/$d $out/$d
      done
    '';
in
{
  inherit fullOpenclaw openclawPackageNoOracle;
}
