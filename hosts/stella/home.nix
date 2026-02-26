{ config, myvars, ... }:

{
  # stella 主机专用的 Home Manager 配置片段
  #
  # 职责：
  # - 仅放“主机特定”的用户级配置（例如 SSH key 使用主机名区分）
  # - 通用 user 配置应放在 user/common 或 user/darwin 内的相应模块中
  #
  # 当前仅为 GitHub SSH 使用基于 hostname 的 identityFile：
  programs.ssh.matchBlocks."github.com".identityFile =
    "${config.home.homeDirectory}/.ssh/${myvars.hostname}";
}
