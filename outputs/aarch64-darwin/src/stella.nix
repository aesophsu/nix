{
  # macOS 主机入口（例如 stella）
  #
  # 职责：
  # - 组合系统级 darwin-modules 与用户级 home-modules
  # - 在此处接线 nix-openclaw overlay / homeManagerModules
  # - 将上面组合后的参数打包成 systemArgs 交给 mylib.macosSystem
  #
  # 注意：
  # - modules/darwin 提供通用的 macOS 系统模块
  # - hosts/darwin-${name} 只放主机特定差异
  # - home/darwin + hosts/darwin-${name}/home.nix 共同组成 Home Manager 配置
  inputs,
  lib,
  mylib,
  myvars,
  system,
  genSpecialArgs,
  ...
}@args:
let
  name = myvars.hostname;

  # =====================================================================================
  # Module composition
  #   - darwin-modules: 系统级 nix-darwin 模块（含主机特定模块）
  #   - home-modules:   用户级 Home Manager 模块（含主机特定模块）
  # 最终会在 mylib.macosSystem 中统一交给 nix-darwin.lib.darwinSystem
  # =====================================================================================

  modules = {
    darwin-modules =
      (map mylib.relativeToRoot [
        # "secrets/darwin.nix"
        "modules/darwin"
        "hosts/darwin-${name}"
      ])
      ++ [
        {
          modules.desktop.fonts.enable = true;
        }
        # nix-openclaw overlay (injected here; modules/darwin has no inputs)
        { nixpkgs.overlays = [ inputs.nix-openclaw.overlays.default ]; }
      ];

    home-modules =
      (map mylib.relativeToRoot [
        "hosts/darwin-${name}/home.nix"
        "home/darwin"
      ])
      ++ [ inputs.nix-openclaw.homeManagerModules.openclaw ];
  };

  # =====================================================================================
  # System arguments
  #   将上面组合好的 modules 与 flake 传入的 args 一起打包，
  #   作为 macosSystem 的输入，统一注入 specialArgs / inputs 等。
  # =====================================================================================

  systemArgs = modules // args;

in
{
  # =====================================================================================
  # macOS host entry
  #   这里仅负责针对当前 hostname 生成一个 darwinConfigurations.<name>，
  #   具体 nix-darwin + Home Manager 的拼装逻辑在 lib/macosSystem.nix 中。
  # =====================================================================================

  darwinConfigurations.${name} = mylib.macosSystem systemArgs;
}
