{ pkgs, myvars, ... }:

{
  home.packages =
    let
      goPackage = builtins.getAttr myvars.toolchains.go.package pkgs;
      nodePackage = builtins.getAttr myvars.toolchains.node.package pkgs;
      pnpmPackage = builtins.getAttr myvars.toolchains.pnpm.package pkgs;
      pythonPackage = builtins.getAttr myvars.toolchains.python.package pkgs;
    in
    [
      # Keep only the base runtimes globally; project-local devshells should
      # carry language-specific tooling such as uv and ruff.
      goPackage
      pythonPackage
      nodePackage
      pnpmPackage
    ];
}
