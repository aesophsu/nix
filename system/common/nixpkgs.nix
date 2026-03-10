{ ... }:

let
  # 仅放行已知需要的 unfree 包，避免意外装上其他非自由软件
  allowUnfreePnames = [
    "google-chrome"
    "zotero"
  ];
in
{
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (pkg.pname or pkg.name or "") allowUnfreePnames;

  nixpkgs.config.permittedInsecurePackages = [
    "openclaw-2026.2.26"
  ];
}
