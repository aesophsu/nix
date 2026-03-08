# Ghostty Font Size Alignment Design

**Date:** 2026-03-08

## Goal

Align Ghostty's configured font size with the current macOS Terminal.app default profile so Ghostty matches the user's existing terminal sizing more closely.

## Context

- Ghostty is configured in `user/darwin/ghostty.nix`.
- The current Ghostty config uses `SF Mono` with `font-size = 15.5`.
- The machine's current Terminal.app default and startup profile is `Basic`.
- The `Basic` profile font decodes to `SFMono-Regular` at size `11.0`.

The user wants Ghostty's font size to match Terminal and ChatGPT as closely as possible. The least ambiguous source of truth available locally is Terminal.app's actual configured font size.

## Chosen Approach

Use the Terminal.app `Basic` profile font size directly:

- keep Ghostty's current `font-family = SF Mono`
- change only `font-size` from `15.5` to `11`
- keep all theme, padding, opacity, cursor, and macOS integration settings unchanged

This is the narrowest possible change and preserves the existing Ghostty look except for size alignment.

## File Boundary

Only modify:

- `user/darwin/ghostty.nix`

Optionally add a short comment noting that the value aligns with the current Terminal.app `Basic` profile.

## Validation

The change is correct when:

- `user/darwin/ghostty.nix` renders `font-size = 11`
- the generated `ghostty/config` text from Nix contains `font-family = SF Mono` and `font-size = 11`
- no other Ghostty settings change
