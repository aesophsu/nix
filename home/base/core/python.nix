{ pkgs, ... }:

let
  # Python 3.12 + common tools (formatting, REPL)
  # ruff is a separate binary, installed separately
  pythonWithTools = pkgs.python312.withPackages (ps:
    with ps; [
      pip
      ipython
      black
      # optional: numpy pandas matplotlib requests
    ]);
  # Exclude bin/idle* to avoid path clash with openclaw
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
    ruff # standalone binary, faster than flake8
    uv # modern pip alternative, project venv recommended
  ];
}
