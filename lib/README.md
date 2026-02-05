# lib

Helpers for the flake; used by outputs to avoid duplication and simplify new hosts.

| File | Role |
|------|------|
| **default.nix** | Exports macosSystem, attrs, relativeToRoot, scanPaths (path helpers). openclaw-package.nix is called from outputs/genSpecialArgs only. |
| **attrs.nix** | Attrset helpers |
| **macosSystem.nix** | [nix-darwin](https://github.com/LnL7/nix-darwin) config builder |
| **openclaw-package.nix** | OpenClaw build (exclude oracle) + PATH-safe wrapper (openclaw* bins); used in genSpecialArgs |
