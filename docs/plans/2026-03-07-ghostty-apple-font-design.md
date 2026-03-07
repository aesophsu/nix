# Ghostty Apple Font Design

**Date:** 2026-03-07

## Goal

Adjust Ghostty to use a font that matches the native macOS terminal aesthetic as closely as possible.

## Constraints

- Prioritize Apple-native visual style over Nerd Font icon coverage.
- Keep the rest of the Ghostty appearance unchanged.
- Avoid introducing extra fallback fonts unless they are strictly necessary.

## Options Considered

### 1. `SF Mono` (recommended)

- Best match for modern macOS and Apple developer tools.
- Clean, restrained appearance for terminal use.
- Some Nerd Font glyphs may not render.

### 2. `Menlo`

- Stable and Apple-native.
- Slightly older visual style than `SF Mono`.

### 3. `Monaco`

- Distinctive but dated.
- Not close to the current Apple default look.

## Design

- Set Ghostty `font-family` to `SF Mono`.
- Remove the `Symbols Nerd Font Mono` fallback.
- Keep the current `font-size`, theme, spacing, and window behavior unchanged.

## Verification

- Inspect the generated Home Manager Ghostty config source.
- Evaluate the rendered `xdg.configFile."ghostty/config".text` output via Nix.
