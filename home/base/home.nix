{ myvars, ... }:
{
  home = {
    inherit (myvars) username;
    stateVersion = "25.11"; # 需与 Home Manager 版本对应
  };
}
