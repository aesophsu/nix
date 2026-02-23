# PostgreSQL 16（Home Manager 服务）

使用 Nixpkgs 包；数据目录、`initdb`、`launchd` 配置在 `home/darwin/services/postgresql/default.nix`。
服务默认登录启动，并使用 Nix 缓存（避免 Homebrew `ghcr.io` 相关问题）。

## 路径

| 项目 | 路径 |
|---|---|
| 数据目录 | `~/.local/share/postgresql/16/` |
| 日志 | `~/.local/share/postgresql/16.log` |
| 配置文件 | `~/.local/share/postgresql/16/postgresql.conf` |

## 服务命令

| 操作 | 命令 |
|---|---|
| 启动 | `launchctl kickstart -k gui/$(id -u)/org.nix.postgresql` |
| 停止 | `launchctl bootout gui/$(id -u)/org.nix.postgresql` |
| 状态 | `launchctl print gui/$(id -u)/org.nix.postgresql` |
| 查看日志 | `tail -f ~/.local/share/postgresql/16.log` |

首次部署时若数据目录不存在，会自动执行 `initdb`。手动初始化命令：
`initdb -D ~/.local/share/postgresql/16 -E UTF8`

## 常用用法

- `psql postgres`
- `createdb myapp`
- `createuser -s $USER`
- 连接串：`postgres://sue@localhost:5432/postgres`
