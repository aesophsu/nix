# Overlays（`overlays/`）

自定义 Nixpkgs overlays。由 `system/common/overlays.nix` 通过 `import ../../overlays` 加载。

当前目录主要由 `default.nix` 聚合其余 `.nix` 文件（目前 overlay 列表基本为空）。

## 约定

- 新增 overlay：添加一个导出 `self: super: { ... }` 的 `.nix` 文件
- `default.nix` 会自动聚合并导出
