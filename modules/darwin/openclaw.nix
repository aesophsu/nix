# nix-openclaw overlay 已移至 outputs/aarch64-darwin/src/stella.nix 内联注入
# （darwin 模块求值时无 inputs，故不在此引用）
# 实际使用的「排除 oracle」包由 outputs/default.nix 的 genSpecialArgs 提供
{ ... }:
{
  # 占位，overlay 在 stella.nix 中通过 inputs.nix-openclaw.overlays.default 添加
}
