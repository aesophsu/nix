{ mylib, ... }:
{
  # macOS 专用系统模块入口
  #
  # 约定：
  # - 当前目录下的每个 *.nix 文件负责一块 macOS 特有配置（apps/system/ssh/security 等）
  # - 通用的基础配置从 ../base 引入（packages、nixpkgs、fonts 等）
  # - hosts/darwin-<name>/default.nix 仅放主机差异，这里保持“主机无关”
  imports = mylib.discoverImports {
    dir = ./.;
    extraImports = [ ../base ];
  };
}
