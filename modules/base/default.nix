{ mylib, ... }:

{
  # 平台无关的基础模块入口（NixOS / Darwin 通用）
  #
  # 约定：
  # - 当前目录下的每个 *.nix 文件都视为一个“基础模块”（如 packages、fonts、nixpkgs 等）
  # - 具体每个模块内部自行通过 enable 选项或子模块划分职责
  # - 与平台相关的逻辑应放在上层（例如 modules/darwin），避免混入 base
  imports = mylib.scanPaths ./.;
}
