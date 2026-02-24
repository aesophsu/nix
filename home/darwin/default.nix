{ mylib, myvars, system, ... }:
{
  home.homeDirectory = mylib.homeDirForSystem {
    inherit system;
    username = myvars.username;
  };
  xdg.enable = true;

  imports = mylib.discoverImports {
    dir = ./.;
    extraImports = [
      ../base/core
      ../base/home.nix
      ../../secrets/home-manager.nix
    ];
  };
}
