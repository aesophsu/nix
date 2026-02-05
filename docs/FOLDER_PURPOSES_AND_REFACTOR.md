# nix 仓各文件夹用途与规整建议

## 一、顶层目录一览

| 目录/文件 | 用途 | 被谁引用 |
|-----------|------|----------|
| **outputs/** | Flake 输出入口：按架构加载 `aarch64-darwin/src/*.nix`，汇总 darwinConfigurations、packages、checks、devShells | `flake.nix` → `import ./outputs` |
| **modules/** | 系统级配置（nix-darwin）：base 通用 + darwin macOS 专用 | `outputs/…/stella.nix` → `modules/darwin`、`hosts/darwin-stella`；darwin 内部引入 `modules/base` |
| **home/** | 用户级配置（Home Manager）：base 跨平台 + darwin 专用（mihomo、openclaw、postgresql） | `stella.nix` → `home/darwin`；darwin 入口引入 `home/base` |
| **hosts/** | 按主机名的覆盖：主机名/计算机名、home 侧 SSH 等 | `stella.nix` → `hosts/darwin-stella` |
| **lib/** | 公共函数：macosSystem、relativeToRoot、scanPaths、attrs、openclaw-package | `outputs/default.nix` → mylib、genSpecialArgs → openclaw-package.nix |
| **vars/** | 集中变量：用户名、主机名、SSH、网络、镜像等 | `outputs/default.nix` → myvars；各模块通过 args 使用 |
| **overlays/** | 自定义 Nixpkgs overlay（当前仅 default.nix，无其它 .nix 文件，等价于空列表） | `modules/base/overlays.nix` → `import ../../overlays` |
| **misc/** | 非 Nix 评估资产（如 certs）；certs 为私有 PKI，被 security.nix 引用 | `modules/base/security.nix` → `../../misc/certs/ecc-ca.crt` |
| **docs/** | 文档：部署、OpenClaw、flake 分析、本说明 | 人工阅读 |
| **.github/** | CI：flake 评估、镜像同步等 | GitHub Actions |
| **.cursor/** | 编辑器规则（如 python-uv） | Cursor IDE |
| **flake.nix / flake.lock** | Flake 入口与锁文件 | Nix |
| **DEPLOYMENT.md** | 重装后部署步骤 | 人工 |

---

## 二、各文件夹具体目标

### 1. outputs/

- **目标**：唯一 flake 输出入口；按系统类型（当前仅 aarch64-darwin）加载「主机碎片」并汇总。
- **内容**：
  - `default.nix`：定义 mylib、myvars、genSpecialArgs，调用 `./aarch64-darwin`，产出 darwinConfigurations / packages / checks / devShells / formatter。
  - `aarch64-darwin/default.nix`：用 haumea 加载 `./src/*.nix`（当前仅 stella.nix），合并 darwinConfigurations。
  - `aarch64-darwin/src/stella.nix`：单机「stella」的模块列表（darwin-modules、home-modules）和 nix-openclaw overlay/homeManager 注入。
- **结论**：结构清晰，无需调整。

### 2. modules/

- **目标**：nix-darwin 系统模块（与平台/主机无关的「能力」）。
- **base/**：通用（字体、nix 设置、overlays、包、安全、用户）；被 darwin 的 default.nix 引入。
- **darwin/**：macOS 专用（Homebrew、系统代理、GUI、Nix 核心、SSH、defaults、openclaw 占位、安全、用户等）。
- **结论**：职责分明，README 已说明；保持即可。

### 3. home/

- **目标**：Home Manager 用户配置，按平台拆分。
- **base/**：跨平台（core：git、neovim、python、starship、theme、shells；home.nix 状态/用户名等）。
- **darwin/**：macOS 专用；default.nix 用 scanPaths 自动加载本目录下 mihomo、openclaw、postgresql 等子模块。
- **结论**：入口简单、扩展方式明确；保持即可。

### 4. hosts/

- **目标**：按「主机名」区分的覆盖层（主机名、计算机名、该机 home 的 SSH identity 等）。
- **内容**：当前仅 `darwin-stella`（default.nix 设主机名，home.nix 设 GitHub identityFile）。
- **结论**：加新机时复制 darwin-stella 为 darwin-<name> 并在 outputs 增加对应 src/<name>.nix 即可；无需改结构。

### 5. lib/

- **目标**：与 flake 输出、主机无关的公共逻辑。
- **内容**：attrs、macosSystem、relativeToRoot/scanPaths（default.nix）、openclaw-package.nix（构建并包装 OpenClaw 包）。
- **结论**：openclaw-package 偏业务，但放 lib 便于 outputs 引用；若以后「业务 helper」增多，可考虑 lib/openclaw.nix 子目录，当前可维持现状。

### 6. vars/

- **目标**：集中存放用户名、主机名、SSH、网络/镜像等变量，避免散落。
- **内容**：default.nix（用户、密码哈希、SSH 公钥）、networking.nix（mihomo、DNS、主机网络、knownHosts）。
- **结论**：单点清晰；保持即可。

### 7. overlays/

- **目标**：自定义 Nixpkgs overlay，供 modules/base/overlays.nix 引用。
- **现状**：仅有 default.nix（自动加载同目录下其它 .nix），当前无其它 .nix，等价于空 overlay 列表。
- **结论**：保留；新增 overlay 时在本目录加新 .nix 即可，无需改引用关系。

### 8. misc/

- **目标**：与 Nix 评估无关的资产（非 flake/模块的辅助文件）。
- **misc/certs/**：私有 PKI（ECC CA、服务器证书、gen-certs.sh）；私钥不入库；由 modules/base/security.nix 引用 `../../misc/certs/ecc-ca.crt`。
- **结论**：已规整为「非评估资产」集中目录；后续若有类似资源可继续放入 misc 下。

### 9. docs/

- **目标**：部署、OpenClaw、flake 与文件夹分析等文档。
- **结论**：保持；可选在 docs 下增加简短 README.md 索引各文档。

---

## 三、规整建议（按优先级）

### 建议 1：在 docs 下增加索引（低成本）

- **操作**：新增 `docs/README.md`，列出 OPENCLAW_SETUP、OPENCLAW_CHECKLIST、FLAKE_FOLDERS_ANALYSIS、FOLDER_PURPOSES_AND_REFACTOR、DEPLOYMENT 等，各一行说明用途。
- **收益**：新人或自己日后快速找到「部署 / OpenClaw / 结构说明」。

### 建议 2：明确 overlays 的「空但有意」

- **操作**：在 `overlays/` 下增加简短 README.md，说明本目录由 modules/base/overlays.nix 引用，当前无额外 overlay，新增时在此目录添加 .nix 文件即可。
- **收益**：避免误以为目录无用或重复。

### 建议 3：保持现有拓扑，不合并目录

- **理由**：outputs / modules / home / hosts / lib / vars 职责已分明，且与 nix-darwin / Home Manager 的常见用法一致。合并（例如把 hosts 并入 modules）会拉长路径、混淆「主机覆盖」与「能力模块」，不建议。
- **可选**：若主机数增多，可考虑 `outputs/aarch64-darwin/src/` 下按主机分文件（已如此），hosts 下保持与主机名一一对应即可。

### 建议 4：certs 迁到 misc（已实施）

- **已做**：新建 `misc/certs`，将原 `certs/` 内容移入；`modules/base/security.nix` 已改为 `../../misc/certs/ecc-ca.crt`；`misc/README.md` 说明本目录用途。

### 建议 5：不新增其它顶层目录

- **结论**：当前顶层已足够（outputs / modules / home / hosts / lib / vars / overlays / misc / docs）。不再新增例如 `config/`、`machines/` 等，除非有明确一类文件需要独立成目录。

---

## 四、引用关系简图

```
flake.nix
  └── outputs/default.nix
        ├── lib/ (mylib, openclaw-package via genSpecialArgs)
        ├── vars/ (myvars)
        └── outputs/aarch64-darwin/
              └── src/stella.nix
                    ├── modules/darwin, modules/base (via darwin)
                    ├── hosts/darwin-stella
                    ├── home/darwin (→ home/base)
                    ├── inputs.nix-openclaw (overlay + homeManagerModules)
                    └── genSpecialArgs → openclawPackageNoOracle
modules/base/overlays.nix → overlays/
modules/base/security.nix → misc/certs/ecc-ca.crt
```

---

## 五、小结

| 项目 | 建议 |
|------|------|
| 各文件夹目标 | 已在上文逐项说明；整体符合「outputs 入口 + modules/home 分平台 + hosts 按机 + lib/vars 共享」的常见模式。 |
| 必做 | 无；当前结构可长期使用。 |
| 推荐 | docs/README.md 索引；overlays/README.md 说明「空目录」用途。 |
| 可选 | （已实施：certs 已迁到 misc/certs。） |
| 不建议 | 合并 modules/home/hosts、或新增多余顶层目录。 |
