# Nix-Darwin's Modules

This directory contains the modules for [Nix-Darwin](https://github.com/LnL7/nix-darwin).

See [ryan4yin/nix-darwin-kickstarter](https://github.com/ryan4yin/nix-darwin-kickstarter) for a more
detailed explanation.

## 已知警告（可忽略）

执行 `darwin-rebuild switch` 时可能出现的无害警告：

| 警告 | 说明 |
|------|------|
| `builtins.toFile` / `options.json` | home-manager 上游 bug [#7935](https://github.com/nix-community/home-manager/issues/7935)，不影响功能 |
| bat `Dockerfile (with bash)` syntax | bat 语法高亮上游问题，不影响使用 |
