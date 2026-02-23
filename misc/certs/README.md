# 私有 PKI / CA（`misc/certs/`）

用于个人服务的私有 PKI / CA（证书颁发）目录，包含公开证书、CSR 配置与生成脚本。

## 文件说明

| 路径 | 说明 |
|---|---|
| `ecc-ca.crt` | ECC CA 证书 |
| `ecc-ca.srl` | CA 序列号文件（证书签发跟踪） |
| `ecc-csr.conf` | OpenSSL CSR 配置 |
| `ecc-server.crt` | 由 ECC CA 签发的服务端证书 |
| `gen-certs.sh` | 自动生成证书脚本 |

## 安全说明

- 私钥文件（`.key`）不提交到仓库
- 私钥保存在单独的 secrets 仓库或本地安全存储
- 当前仓库仅保存公开证书与配置文件，便于参考与重建

## 使用

运行 `./gen-certs.sh` 生成或更新证书。
