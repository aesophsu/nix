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
  # 排除 bin/idle*，避免与 openclaw 包（也带 Python idle）在 home-manager path 中冲突
  pythonWithToolsNoIdle = pkgs.runCommand "python312-env-no-idle"
    { passthru = pythonWithTools.passthru or { }; }
    ''
      mkdir -p $out/bin
      for x in ${pythonWithTools}/bin/*; do
        n=$(basename "$x")
        case "$n" in
          idle|idle3|idle3.*) : ;;
          *) ln -s "$x" $out/bin/ ;;
        esac
      done
      for d in lib share; do
        [ -d ${pythonWithTools}/$d ] && ln -s ${pythonWithTools}/$d $out/$d
      done
    '';
in
{
  home.packages = with pkgs; [
    pythonWithToolsNoIdle
    ruff # 独立二进制，比 flake8 更快
    uv # 现代 pip 替代，项目级 venv 推荐
  ];
}
