{ pkgs, ... }:

{
  # 系统级通用 CLI 工具
  #
  # 约定：
  # - 这里只放“真正系统级”的工具（例如 openssl / mas 等）
  # - 日常开发工具、语言运行时和 GUI 应用优先放在 Home Manager 中：
  #     - CLI / 终端工具（含 python/uv/ruff/git/node/docker/jq/curl）：user/common/core/packages.nix
  #     - macOS GUI 应用：system/darwin/apps.nix 的 Homebrew casks
  environment.variables.EDITOR = "nvim --clean";
  environment.systemPackages = with pkgs; [
    openssl
    llvmPackages.openmp
  ];
}
