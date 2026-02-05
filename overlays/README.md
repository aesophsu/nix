# overlays

Custom Nixpkgs overlays. Loaded by `modules/base/overlays.nix` via `import ../../overlays`.

Only `default.nix` here (loads other .nix in this dir) → effectively empty overlay list. To add an overlay: add a .nix that exports `self: super: { ... }`; default.nix picks it up.
