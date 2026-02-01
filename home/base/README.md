# Home Manager's Base Submodules

This directory contains cross-platform base configurations that are shared between Linux and Darwin
systems.

## Configuration Structure

### Core System

- **core/**: Essential cross-platform configurations
  - **core.nix**: Minimal home-manager configuration
  - **shells/**: Shell configurations (bash, zsh, fish, nu)
  - **git.nix**: Git configuration and aliases
  - **pip.nix**: Python package management
  - **starship.nix**: Cross-shell prompt configuration
  - **theme.nix**: Color schemes and theming

### System Management

- **home.nix**: Main home manager configuration file
