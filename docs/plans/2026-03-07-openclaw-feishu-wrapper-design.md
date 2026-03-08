# OpenClaw Feishu Wrapper Design

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Integrate the third-party `clawdbot-feishu` channel plugin into `nix-openclaw` declaratively for local deployment on macOS.

**Architecture:** Keep `nix-openclaw` as the source of truth. Add a small local wrapper flake that exports `openclawPlugin` for the Feishu repo, symlink the plugin extension into `~/.openclaw/extensions/feishu`, and keep sensitive Feishu credentials in file-backed env vars so they never land in the Nix store.

**Tech Stack:** Nix flakes, Home Manager, nix-openclaw, OpenClaw plugin system, Feishu plugin `m1heng/clawdbot-feishu`

---

## Decisions

- Use Feishu websocket mode, not webhook mode, for the initial deployment.
- Keep OpenAI Codex via OAuth as the model provider in the core OpenClaw config.
- Use a local wrapper flake because `clawdbot-feishu` does not export `openclawPlugin`.
- Provide Feishu App ID and App Secret through file-backed plugin env vars:
  - `FEISHU_APP_ID`
  - `FEISHU_APP_SECRET`
- Keep Feishu channel behavior in `programs.openclaw.config.channels.feishu` and do not store Feishu secrets there.

## Risks

- Current `nix-openclaw` module docs describe plugin installation into `~/.openclaw/extensions`, but the visible module code does not obviously materialize the extension tree. The local flake therefore also declares an explicit `home.file` symlink for the Feishu extension directory.
- OpenAI OAuth still requires a runtime login step after activation.

## Required User Inputs

- `FEISHU_APP_ID`
- `FEISHU_APP_SECRET`

Optional for later webhook mode only:

- `FEISHU_VERIFICATION_TOKEN`
- `FEISHU_ENCRYPT_KEY`
