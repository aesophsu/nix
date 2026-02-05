{
  # macOS 系统拼装函数
  #
  # 职责：
  # - 基于 nix-darwin.lib.darwinSystem 构建 darwinConfiguration
  # - 当 home-modules 非空时，自动启用 Home Manager 集成
  # - 将 flake 提供的 specialArgs（见 genSpecialArgs）同时暴露给
  #   - 系统级模块（darwin-modules）
  #   - 用户级模块（home-modules + home-manager.extraSpecialArgs）
  #
  # 约定：
  # - darwin-modules：系统级配置（modules/darwin + hosts/darwin-<name>）
  # - home-modules：  用户级配置（hosts/darwin-<name>/home.nix + home/darwin 等）
  # - myvars：        至少包含 username/hostname 等基础信息
  #
  # 典型调用方：outputs/aarch64-darwin/src/<host>.nix
  lib,
  inputs,
  darwin-modules,
  home-modules ? [ ],
  myvars,
  system,
  genSpecialArgs,
  specialArgs ? (genSpecialArgs system),
  ...
}:

let
  inherit (inputs) home-manager nix-darwin;
in
nix-darwin.lib.darwinSystem {
  inherit system specialArgs;

  modules =
    darwin-modules
    # 仅当存在 home-modules 时才启用 Home Manager，避免空配置也加载 HM。
    ++ (lib.optionals ((lib.lists.length home-modules) > 0) [
      home-manager.darwinModules.home-manager
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.backupFileExtension = "home-manager.backup";

        # extraSpecialArgs：对所有 Home Manager 模块暴露同一份 specialArgs。
        home-manager.extraSpecialArgs = specialArgs;
        home-manager.users."${myvars.username}".imports = home-modules;
      }
    ]);
}
