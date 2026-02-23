{ lib, pkgs, ... }:
{
  services.greetd = {
    enable = true;
    useTextGreeter = true;
    settings = {
      default_session = {
        user = "greeter";
        command =
          "${pkgs.tuigreet}/bin/tuigreet --time --remember --remember-session --asterisks --cmd ${pkgs.niri}/bin/niri";
      };
    };
  };

  programs.niri.enable = true;

  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      waylandFrontend = true;
      addons = with pkgs; [
        qt6Packages.fcitx5-chinese-addons
        (fcitx5-rime.override { rimeDataPkgs = [ rime-data rime-ice ]; })
      ];
      settings.globalOptions = {
        Hotkey = {
          EnumerateWithTriggerKeys = "True";
        };
      };
    };
  };

  security.rtkit.enable = true;
  programs.dconf.enable = true;
  services.gvfs.enable = true;
  services.tumbler.enable = true;
  services.udisks2.enable = true;
  services.upower.enable = true;

  services.pipewire = {
    enable = true;
    audio.enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  services.pulseaudio.enable = false;

  xdg.portal.xdgOpenUsePortal = true;

  programs.thunar.enable = true;
  programs.xfconf.enable = true;
}
