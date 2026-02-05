# vars

Shared variables for all hosts.

| File | Role |
|------|------|
| default.nix | User (username, full name, email), initialHashedPassword, mainSshAuthorizedKeys, secondaryAuthorizedKeys |
| networking.nix | mihomo (ports, proxy URLs; match home/darwin/mihomo config), nameservers, hostsAddr/hostsInterface (DHCP), ssh knownHosts |

Mirrors: Nix store (modules/base/nix.nix), Homebrew (modules/darwin/apps.nix), PyPI (home/base/core/pip.nix, mihomo no_proxy). Mainland-friendly.
