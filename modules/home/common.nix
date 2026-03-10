{ myvars, ... }:

{
  home = {
    inherit (myvars) username;
    stateVersion = "25.11"; # match Home Manager version
  };
}
