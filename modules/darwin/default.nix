{ mylib, ... }:
{
  imports = (mylib.scanPaths ./.) ++ [
    ../base # Shared config for NixOS and Darwin
  ];
}
