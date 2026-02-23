# 文档生成脚本

`scripts/docs/generate.py` 负责生成并校验 `docs/generated/*`。

## 用法

```bash
python3 scripts/docs/generate.py --write
python3 scripts/docs/generate.py --check
```

默认会执行 `nix eval --json .#docInventory` 读取输入数据。

在 flake `checks.<system>.docs-sync` 中会通过 `--inventory-file` 传入预先生成的 JSON，以避免在 derivation 内再次调用 `nix eval`。
