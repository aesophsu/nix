{ lib, pkgs, mylib, myvars, system ? "x86_64-linux", ... }:
let
  username = myvars.username;
in
{
  imports = [
    ./programs/shell.nix
    ./programs/kitty.nix
    ./programs/neovim.nix
    ./desktop/niri.nix
    ./input/rime.nix
    ./packages.nix
  ];

  home = {
    username = username;
    homeDirectory = mylib.homeDirForSystem {
      inherit system;
      inherit username;
    };
    stateVersion = "25.11";
  };

  xdg.enable = true;

  home.activation.shakaRimeLocalFallback = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ -d /etc/nixos/local/rime ]; then
      mkdir -p "$HOME/.local/share/fcitx5/rime/local"
      cp -rn /etc/nixos/local/rime/. "$HOME/.local/share/fcitx5/rime/local/" || true
    fi
  '';
}
