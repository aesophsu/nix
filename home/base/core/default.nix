{ mylib, ... }:

{
  imports = mylib.scanPaths ./.; # auto-import .nix files and subdirs under current directory
}
