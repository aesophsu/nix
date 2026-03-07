{ pkgs, myvars, ... }:

{
  home.packages =
    let
      nodePackage = builtins.getAttr myvars.toolchains.node.package pkgs;
      pythonPackage = builtins.getAttr myvars.toolchains.python.package pkgs;
    in
    [
      # Keep only the base runtimes globally; project-local devshells should
      # carry language-specific tooling such as uv and ruff.
      pythonPackage
      nodePackage
    ];
}
