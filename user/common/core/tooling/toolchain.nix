{ pkgs, myvars, ... }:

{
  home.packages =
    let
      nodePackage = builtins.getAttr myvars.toolchains.node.package pkgs;
      pythonPackage = builtins.getAttr myvars.toolchains.python.package pkgs;
    in
    [
      pythonPackage
      pkgs.uv
      pkgs.ruff
      nodePackage
    ];
}
