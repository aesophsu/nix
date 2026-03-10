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
      ../common/core
      ../common/home.nix
      ./services
    ];
    exclude = [ ./services ];
  };
}
