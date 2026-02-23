{ pkgs, ... }:

{
  # 系统级通用 CLI 工具
  #
  # 约定：
  # - 这里只放“真正系统级”的工具（例如 git / openssl / mas 等）
  # - 日常开发工具、语言运行时和 GUI 应用优先放在 Home Manager 中：
  #     - CLI / 终端工具：home/base/core/packages.nix
  #     - 语言栈（Python 等）：home/base/core/python.nix
  #     - macOS GUI 应用：home/darwin/apps/gui.nix
  environment.variables.EDITOR = "nvim --clean";
  environment.systemPackages = with pkgs; [
    git
    git-lfs
    openssl
    mas
    llvmPackages.openmp
  ];
}
