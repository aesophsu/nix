# misc

存放与 Nix 评估无关的资产（非 flake 输出/模块的辅助文件）。

| 子目录 | 用途 |
|--------|------|
| **certs/** | 私有 PKI/CA（ECC 证书、gen-certs.sh）；被 `modules/base/security.nix` 引用 |
