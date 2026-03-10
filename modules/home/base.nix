{
  mylib,
  myvars,
  system,
  ...
}:
{
  imports = [ ./common.nix ];

  home.homeDirectory = mylib.homeDirForSystem {
    inherit system;
    username = myvars.username;
  };

  xdg.enable = true;
}
