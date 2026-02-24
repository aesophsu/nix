{ inputs ? { } }:
let
  localRoot = ./local;
  localDirEntries =
    if builtins.pathExists localRoot then
      builtins.attrNames (builtins.readDir localRoot)
    else
      [ ];
  localHasUsableContent = builtins.any (name: name != ".gitkeep") localDirEntries;
  hasPrivate = inputs ? mysecrets;
in
if hasPrivate then
  {
    enabled = true;
    mode = "private-flake-input";
    root = inputs.mysecrets;
  }
else if builtins.pathExists localRoot && localHasUsableContent then
  {
    enabled = true;
    mode = "local-fallback";
    root = localRoot;
  }
else
  {
    enabled = false;
    mode = "disabled";
    root = null;
  }
