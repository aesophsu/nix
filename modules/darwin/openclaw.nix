# 为 Home Manager 提供 openclaw 包与 overlay（Gateway、macOS 应用、工具链）
# 实际使用的「排除 oracle」包由 outputs/default.nix 的 genSpecialArgs 提供
{ inputs, ... }:
{
  nixpkgs.overlays = [ inputs.nix-openclaw.overlays.default ];
}
