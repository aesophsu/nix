# Home Manager's Submodules

This directory contains all Home Manager configurations organized by platform and functionality.

## Current Structure

```
home/
├── base/              # Cross-platform home manager configurations
│   ├── core/          # Essential applications and settings
│   │   ├── shells/    # Shell configurations (Nushell, Zellij)
│   │   └── ...
│   └── home.nix       # Main home manager entry point
└── darwin/            # macOS-specific home manager configurations
    └── ...
```

## Module Overview

1. **base**: The base module suitable for both Linux and macOS
   - Cross-platform applications and settings
   - Shared configurations for editors, shells, and essential tools

2. **darwin**: macOS-specific configuration
   - macOS applications and services
   - Platform-specific integrations (Aerospace, Squirrel, etc.)
