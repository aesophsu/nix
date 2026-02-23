{ pkgs, ... }:

let
  # Python 3.12 + common tools (REPL); format/lint via ruff (standalone)
  pythonWithTools = pkgs.python312.withPackages (ps:
    with ps; [
      pip
      ipython
      numpy
      pandas
      matplotlib
      requests
    ]);
  # Exclude bin/idle* to avoid PATH clashes with other tools
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
    ruff # format + lint (replaces black + flake8)
    uv # modern pip alternative, project venv recommended
  ];
}
