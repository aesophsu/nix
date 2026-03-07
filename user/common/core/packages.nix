{ pkgs, ... }:

let
  devshellTools = pkgs.stdenvNoCC.mkDerivation {
    pname = "devshell-tools";
    version = "1.0.0";
    src = ../../..;

    installPhase = ''
      runHook preInstall

      mkdir -p "$out/bin" "$out/share/devshell-templates"
      cp "$src/user/common/core/scripts/devshell-init" "$out/bin/devshell-init"
      cp "$src/user/common/core/scripts/devshell-attach" "$out/bin/devshell-attach"
      chmod +x "$out/bin/devshell-init" "$out/bin/devshell-attach"
      cp -R "$src/templates/devshell/." "$out/share/devshell-templates/"

      runHook postInstall
    '';
  };
in

{
  # Base user-level stable CLI packages.
  # Rolling user tools such as codex CLI are installed outside Nix on purpose.
  home.packages = [
    pkgs.nix-index
    pkgs.nix-tree
    pkgs.gnupg
    pkgs.ollama
    pkgs.tree
    pkgs.wget
    pkgs.go
    devshellTools
  ];

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
