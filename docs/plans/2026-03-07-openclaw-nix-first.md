# OpenClaw Nix-First Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Codify the approved OpenClaw `Nix-first` operating model in repository guidance so future OpenClaw work defaults to declarative Nix changes and uses the OpenClaw CLI only for diagnosis and verification.

**Architecture:** Add a repository-level `AGENTS.md` because this repo currently has no local agent guidance file. Keep the document narrow: define the OpenClaw source-of-truth rule, list what is directly allowed, what must go through Nix, and what requires an explicit user exception. Link the rule set back to the design document for rationale.

**Tech Stack:** Markdown, repository agent instructions, OpenClaw operational workflow, Nix-managed configuration

---

### Task 1: Confirm the repository guidance entry point

**Files:**
- Verify: `AGENTS.md`
- Verify: `docs/plans/2026-03-07-openclaw-nix-first-design.md`

**Step 1: Check whether a repository-level `AGENTS.md` already exists**

Run: `ls -la /Users/sue/nix`
Expected: no `AGENTS.md` is present, so a new repository-level guidance file is needed.

**Step 2: Re-read the approved design**

Run: `sed -n '1,220p' docs/plans/2026-03-07-openclaw-nix-first-design.md`
Expected: confirms the final approved operating model and task boundaries.

### Task 2: Add repository-level OpenClaw collaboration rules

**Files:**
- Create: `AGENTS.md`

**Step 1: Write the guidance skeleton**

Create sections for:

- scope
- default operating rule
- directly allowed OpenClaw actions
- actions that must go through Nix
- explicit-exception actions

**Step 2: Encode the core rule**

State plainly that:

- Nix is the source of truth for persistent OpenClaw state
- OpenClaw CLI is for diagnosis, inspection, and verification by default
- imperative persistent changes are not the default path in this repository

**Step 3: Add a concise reference back to the design doc**

Include a short note that the rationale lives in:

```text
docs/plans/2026-03-07-openclaw-nix-first-design.md
```

### Task 3: Verify the guidance before completion

**Files:**
- Verify: `AGENTS.md`
- Verify: `docs/plans/2026-03-07-openclaw-nix-first.md`

**Step 1: Read the final `AGENTS.md`**

Run: `sed -n '1,220p' AGENTS.md`
Expected: clearly states the OpenClaw `Nix-first` boundary and contains no conflicting imperative guidance.

**Step 2: Confirm the plan file exists**

Run: `sed -n '1,220p' docs/plans/2026-03-07-openclaw-nix-first.md`
Expected: shows the implementation plan header and tasks.

**Step 3: Check git status**

Run: `git status --short`
Expected: shows the new `AGENTS.md` and plan/design docs as expected.
