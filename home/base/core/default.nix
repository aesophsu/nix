{ mylib, ... }:
{
  imports = mylib.scanPaths ./.; # 自动导入当前目录下的 .nix 文件和子目录
}
