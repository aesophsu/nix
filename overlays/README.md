# overlays

本目录提供**自定义 Nixpkgs overlay**，由 `modules/base/overlays.nix` 通过 `import ../../overlays args` 引入。

当前目录下除 `default.nix` 外没有其它 `.nix` 文件，因此等价于「空 overlay 列表」。  
新增 overlay 时在此目录添加新的 `.nix` 文件（导出函数 `self: super: { ... }` 等），`default.nix` 会自动加载。
