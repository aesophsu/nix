{ ... }:

{
  # 允许安装非自由软件，用于 macOS 上的浏览器等 GUI 应用
  # （例如 google-chrome、zotero）。如果以后不需要，可以在这里关闭。
  nixpkgs.config.allowUnfree = true;
}

