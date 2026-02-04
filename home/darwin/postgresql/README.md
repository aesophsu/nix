# PostgreSQL 配置

Nixpkgs PostgreSQL 16，由 **`home/darwin/postgresql/default.nix`** 提供：包、数据目录、initdb 与 launchd，开机自启。使用 Nix 缓存下载，避免 Homebrew ghcr.io 在国内网络环境下的下载失败。

## 路径

| 项目 | 路径 |
|------|------|
| 数据目录 | `~/.local/share/postgresql/16/` |
| 日志 | `~/.local/share/postgresql/16.log` |
| 配置文件 | `~/.local/share/postgresql/16/postgresql.conf` |

## 服务管理

| 操作 | 命令 |
|------|------|
| 启动 | `launchctl kickstart -k gui/$(id -u)/org.nix.postgresql` |
| 停止 | `launchctl bootout gui/$(id -u)/org.nix.postgresql` |
| 查看状态 | `launchctl print gui/$(id -u)/org.nix.postgresql` |
| 查看日志 | `tail -f ~/.local/share/postgresql/16.log` |

部署后服务会自动启动（`RunAtLoad = true`）。若需手动启动，执行上述「启动」命令。

## 常用命令

```bash
# 连接默认数据库
psql postgres

# 创建数据库
createdb myapp

# 连接指定数据库
psql myapp

# 创建超级用户（默认与 macOS 用户名相同）
createuser -s $USER
```

## 连接字符串

```
postgres://sue@localhost:5432/postgres
```

## 首次部署

1. `darwin-rebuild switch` 会应用配置
2. home-manager 会执行 initdb（若数据目录不存在）并启动服务
3. 若 initdb 未自动执行，可手动：`initdb -D ~/.local/share/postgresql/16 -E UTF8`
