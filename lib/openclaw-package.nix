# OpenClaw 包构建与 PATH 安全包装（排除 oracle、仅暴露 openclaw* bin）
# 供 outputs 的 genSpecialArgs 调用，避免 outputs/default.nix 内联膨胀
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
