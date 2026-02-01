args:
let
  overlayFiles = builtins.filter (
    f: f != "default.nix" && f != "README.md" && (builtins.match ".*\\.nix$" f != null)
  ) (builtins.attrNames (builtins.readDir ./.));
in
builtins.map (f: import (./. + "/${f}") args) overlayFiles
