# Home Manager · base (cross-platform)

Shared by Linux and Darwin.

| Path | Role |
|------|------|
| **home.nix** | stateVersion, username |
| **core/** | Apps and settings; core/default.nix scanPaths loads all .nix and subdirs |
| core/core.nix, git.nix, neovim.nix, pip.nix, python.nix, starship.nix, theme.nix, shells/ | As named |

`home/darwin/default.nix` imports `../base/core` and `../base/home.nix`, so all Darwin users get base.
