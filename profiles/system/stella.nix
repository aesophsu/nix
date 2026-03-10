{
  imports = [
    ../../modules/system/common.nix
    ../../modules/system/darwin/default.nix
    ../../hosts/stella/system.nix
    {
      modules.desktop.fonts.enable = true;
    }
  ];
}
