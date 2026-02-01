{ pkgs, ... }:

let
  # Python 3.12 + 常用工具（格式化、REPL）
  # ruff 为独立二进制，单独安装
  pythonWithTools = pkgs.python312.withPackages (ps:
    with ps; [
      pip
      ipython
      black
      # 按需添加：numpy pandas matplotlib requests
    ]);
in
{
  home.packages = with pkgs; [
    pythonWithTools
    ruff # 独立二进制，比 flake8 更快
    uv # 现代 pip 替代，项目级 venv 推荐
  ];
}
