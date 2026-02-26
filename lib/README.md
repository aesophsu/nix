# 辅助库（`lib/`）

供 flake `outputs` 复用的辅助函数与构建封装，减少重复配置并简化 `stella` 的组装。

| 路径 | 说明 |
|---|---|
| `default.nix` | 导出 `macosSystem`、`relativeToRoot`、`scanPaths` 等公共函数（不再包含 host registry 抽象） |
| `macosSystem.nix` | [nix-darwin](https://github.com/LnL7/nix-darwin) 系统组装入口 |
