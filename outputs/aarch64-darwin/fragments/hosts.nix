{
  # macOS 主机入口（通用 loader）
  #
  # 职责：
  # - 从 hostRegistry.darwin 中筛选当前 system 的所有主机
  # - 组合系统级 darwin-modules 与用户级 home-modules
  # - 生成 darwinConfigurations.<name>
  #
  # 注意：
  # - modules/darwin 提供通用的 macOS 系统模块
  # - hosts/darwin-${name} 只放主机特定差异
  # - home/darwin + hosts/darwin-${name}/home.nix 共同组成 Home Manager 配置
  inputs,
  lib,
  mylib,
  myvars,
  hostRegistry,
  system,
  genSpecialArgs,
  ...
}@args:
let
  hostLib = mylib.hostRegistry;
  hostsForSystem = hostLib.hostsForPlatformSystem hostRegistry "darwin" system;

  mkDarwinConfig =
    host:
    let
      name = host.name;
      homePath = host.homePath;
      modules = {
        darwin-modules =
          (map mylib.relativeToRoot [
            # "secrets/darwin.nix"
            "modules/darwin"
            host.hostPath
          ])
          ++ [
            {
              modules.desktop.fonts.enable = true;
            }
          ];

        home-modules =
          (map mylib.relativeToRoot [
            homePath
            "home/darwin"
          ]);
      };
      systemArgs = modules // args;
    in
    {
      darwinConfigurations.${name} = mylib.macosSystem systemArgs;
    };
in
{
  darwinConfigurations = hostLib.mergeField "darwinConfigurations" (map mkDarwinConfig hostsForSystem);
}
