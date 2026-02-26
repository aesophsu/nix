{ ... }:

let
  # 仅放行已知需要的 unfree 包，避免意外装上其他非自由软件
  # code-cursor 在 nixpkgs 中 derivation 的 pname 为 "cursor"
  allowUnfreePnames = [
    "cursor"
    "google-chrome"
    "zotero"
  ];
in
{
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (pkg.pname or pkg.name or "") allowUnfreePnames;
}

