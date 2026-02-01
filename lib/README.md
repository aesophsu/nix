# Library

This directory contains helper functions used by `flake.nix` to reduce code duplication and make it
easier to add new machines.

## Current Functions

### Core System Generators

1. **`attrs.nix`** - Attribute set manipulation utilities
2. **`macosSystem.nix`** - macOS configuration generator for
   [nix-darwin](https://github.com/LnL7/nix-darwin)

### Entry Point

3. **`default.nix`** - Main entry point that imports all functions and exports them as a single
   attribute set

## Usage

These functions are designed to:

- Generate consistent configurations across different architectures
- Provide type-safe configuration for complex systems
- Enable easy scaling of the infrastructure
- Support both local development and production deployments
