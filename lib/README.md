# Library

This directory contains helper functions used by `flake.nix` to reduce code duplication and make it
easier to add new machines.

## Current Functions

### Core System Generators

1. **`attrs.nix`** - Attribute set manipulation utilities
2. **`macosSystem.nix`** - macOS configuration generator for
   [nix-darwin](https://github.com/LnL7/nix-darwin)

3. **`openclaw-package.nix`** - Builds the OpenClaw package (excluding oracle) and a PATH-safe wrapper (only `openclaw*` bins) for use in `genSpecialArgs`

### Entry Point

4. **`default.nix`** - Main entry point that imports all functions and exports them as a single
   attribute set

## Usage

These functions are designed to:

- Generate consistent configurations across different architectures
- Provide type-safe configuration for complex systems
- Enable easy scaling of the infrastructure
- Support both local development and production deployments
