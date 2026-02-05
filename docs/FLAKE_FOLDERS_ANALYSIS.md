# Flake 相关文件夹分析与规整建议

## 一、四个文件夹的职责与内容概览

| 文件夹 | 性质 | 主要内容 | 被谁引用 |
|--------|------|----------|----------|
| **flake-utils** | 上游库 (numtide) | 纯 Nix 工具函数：`eachSystem`、`simpleFlake`、`filterPackages`、`flattenTree` 等；含 examples、check-utils | **nix**（path）、**nix-openclaw**（其 flake 的 input） |
| **nix** | 你的主配置仓 | nix-darwin + home-manager：outputs、modules、home、hosts、lib、vars、overlays、misc（certs）、docs | 本地 `darwin-rebuild` 入口 |
| **nix-openclaw** | 上游 (openclaw) | OpenClaw 的 Nix 封装：packages、overlay、home-manager 模块、darwin 模块、checks、scripts、templates | **nix**（path）；其自身依赖 flake-utils、home-manager、nix-steipete-tools |
| **nix-steipete-tools** | 上游 (openclaw) | steipete 系列工具的 Nix 包：summarize、gogcli、bird、peekaboo、oracle 等；每个工具带 `tools/<name>/flake.nix` + skills | **nix**（path）、**nix-openclaw**（把 steipete 包打进 openclaw 镜像） |

---

## 二、依赖关系（谁用谁）

```
                    ┌─────────────────┐
                    │   flake-utils    │  仅提供 lib，无业务逻辑
                    └────────┬────────┘
                             │
     ┌───────────────────────┼───────────────────────┐
     │                       │                       │
     ▼                       ▼                       │
┌─────────┐           ┌──────────────┐                │
│   nix   │◄──path───►│ nix-openclaw │◄───────────────┘
│ (主配置)│           │ (openclaw 包)│
└────┬────┘           └──────┬───────┘
     │                        │
     │ path                   │ input
     ▼                        ▼
┌─────────────────────┐  ┌─────────────────────┐
│ nix-steipete-tools  │◄─┤ (steipete 工具包)    │
│ (工具包仓库)         │  └─────────────────────┘
└─────────────────────┘
```

- **nix**：通过 `path:/Users/sue/claw/<name>` 引用 flake-utils、nix-openclaw、nix-steipete-tools（三者统一放在 `~/claw`，避免 darwin-rebuild 时 daemon 走 GitHub）。
- **nix-openclaw**：通过 flake inputs 使用 flake-utils、home-manager、nix-steipete-tools；你本地用 path 时，nix 的 flake 把这三个 input 用 `follows` 传给它。

---

## 三、可规整与可简化点

### 1. 你完全可控的只有 **nix** 仓

- **flake-utils / nix-openclaw / nix-steipete-tools** 都是上游仓库，目录结构由上游决定，本地只做 clone + 可选 path 引用，**不建议改它们内部结构**。
- 能优化的是：**nix 仓内**怎么引用、怎么减少重复、怎么把「OpenClaw 集成方式」写清楚，避免以后觉得「文件多又散」。

### 2. 文档重复：`documents/` 与 nix-openclaw 模板

- **nix** 里：`home/darwin/openclaw/documents/`（AGENTS.md、SOUL.md、TOOLS.md）
- **nix-openclaw** 里：`templates/agent-first/documents/` 内容一致
- 若你希望和上游模板保持一致，可二选一：
  - **方案 A**：保留当前 nix 下的一份，在 README 或本文档里注明「与 nix-openclaw 的 agent-first 模板同步，需手动或脚本同步」。
  - **方案 B**：在 nix 里不存 documents 副本，改为通过 Nix 引用模板路径（需在 `genSpecialArgs` 里传入 `openclawDocumentsPath = inputs.nix-openclaw + "/templates/agent-first/documents"`，并在 `home/darwin/openclaw/default.nix` 里用 `documents = openclawDocumentsPath`）。这样只维护上游一份，但依赖 path 输入指向的 nix-openclaw 目录。

### 3. OpenClaw 集成逻辑分散在 3 处（建议用文档收拢）

- **outputs/default.nix**：`genSpecialArgs` 里调 `lib/openclaw-package.nix`，得到 `openclawPackageNoOracle`，并注入 overlay 在 **outputs/aarch64-darwin/src/stella.nix**。
- **lib/openclaw-package.nix**：真正调 nix-openclaw 的 packages、排除 oracle、做 PATH 安全包装。
- **modules/darwin/openclaw.nix**：占位注释，说明 overlay 已移到 stella.nix。

建议：在 **nix** 仓里加一段简短说明（例如在 `docs/OPENCLAW_SETUP.md` 或 `lib/README.md`）写清：

- 为何用 path 引用三个 flake（避免 daemon 网络）。
- overlay 在哪注入（stella.nix）、为何不在 modules/darwin 里引 inputs。
- 谁提供「排除 oracle 的 openclaw 包」与 PATH 安全（lib/openclaw-package.nix + genSpecialArgs）。
- home 里 OpenClaw 配置入口是 `home/darwin/openclaw/default.nix`。

这样以后看「OpenClaw 相关」只需看这一条链路，不会觉得「到处都有 openclaw 很乱」。

### 4. 是否要「减少文件夹数量」本身

- **四个文件夹**：一个是第三方工具库、两个是上游业务仓、一个是你的主配置，职责清晰。复杂感主要来自「引用链」和「OpenClaw 集成分散在 3 处」，而不是「多了一个 flake 目录」。
- 若希望**少维护本地 clone**：
  - 可尝试把 flake-utils / nix-steipete-tools / nix-openclaw 从 `path:` 改为带 `rev` 的 GitHub URL，首次在「开代理」环境做一次 `nix flake update`，之后用 cache；这样就不必在本地保留三个 clone。代价是：未命中 cache 时 daemon 要访问 GitHub，你注释里已说明国内可能需代理。
- 若坚持**完全离线/无代理** rebuild，保留 path 是合理选择，此时「四个文件夹」是必然的，重点放在**文档和 nix 仓内结构**即可。

---

## 四、建议执行的规整（仅限 nix 仓）

1. **文档**  
   - 在 `docs/` 或 `lib/README.md` 中增加「OpenClaw 集成流程」小节（或扩写现有 OPENCLAW_SETUP.md），内容覆盖第三节第 3 点。
2. **documents 二选一**  
   - 要么保持现状并注明「与 nix-openclaw 的 agent-first 模板一致，需手动同步」；  
   - 要么改为使用 `openclawDocumentsPath` 引用模板目录，删除 `home/darwin/openclaw/documents/` 副本。
3. **不改动**  
   - flake-utils、nix-openclaw、nix-steipete-tools 的目录结构保持不动；  
   - 若需要，可在 nix 的 README 或 DEPLOYMENT 里列出「本地 path 依赖的 clone 路径与用途」，方便以后自己或他人一眼看懂四个文件夹各自做什么。

---

## 五、小结

| 问题 | 结论 |
|------|------|
| 四个文件夹能否合并成一个？ | 不建议。职责不同：一个工具库、两个上游业务仓、一个你的配置仓。 |
| 能否减少「复杂感」？ | 可以。通过「在 nix 仓内集中文档 + 可选统一 documents 来源」来收拢 OpenClaw 相关逻辑。 |
| 能否进一步规整？ | 只适合在 **nix** 仓内规整：文档、documents 来源；上游三仓保持原样。 |

---

## 六、path 依赖已统一到 ~/claw（已实施）

三个 path 依赖已移入统一目录，结构如下：

```
~/claw/
├── README.md           # 说明与首次克隆/迁移命令
├── flake-utils/
├── nix-openclaw/
└── nix-steipete-tools/
```

**nix** 的 `flake.nix` 中已改为 `path:/Users/sue/claw/<name>`。若在新机器或新 home 下首次克隆，执行 `~/claw/README.md` 中的命令即可。
