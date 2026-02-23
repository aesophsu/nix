# Host Overrides · `darwin-stella`

Host-specific diffs only. Keep this directory small and avoid duplicating shared logic from `modules/darwin` or `home/darwin`.

## Boundary

- Put here: machine identity and hardware/runtime differences for `stella` only
- Put here: host-only Home Manager overrides (for example, SSH key path bound to hostname)
- Do not put here: reusable macOS defaults, Homebrew policy, shared packages, shell preferences, services
- Do not put here: general user config that should apply to future Darwin hosts

## Files

| 路径 | 说明 |
|---|---|
| `default.nix` | 系统层主机身份（`hostName`、`computerName`、`localHostName`） |
| `home.nix` | 用户层主机差异（当前仅 GitHub SSH `identityFile`） |

## Rule of Thumb

If another Mac would likely need the same config, move it to `modules/darwin` or `home/darwin` instead of keeping it here.
