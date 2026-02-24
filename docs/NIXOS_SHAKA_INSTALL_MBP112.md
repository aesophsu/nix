# 文档迁移：MacBookPro11,2 手动安装 `shaka`

该安装文档已迁移到新的 bootstrap 子flake目录：

- `nixos-installer/README.md`

推荐从仓库根目录阅读与执行：

```bash
cd /Users/sue/Code/nix

# 查看安装文档
sed -n '1,220p' nixos-installer/README.md

# 构建 installer ISO（远程 Linux）
nixos-installer/scripts/build-remote.sh --dry-run \
  --host <ssh-host> \
  --remote-dir <remote-dir>
```

说明：保留本文件一个迁移周期，后续可能删除。
