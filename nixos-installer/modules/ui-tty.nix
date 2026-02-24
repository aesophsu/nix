{ ... }:
{
  environment.etc."issue".text = ''
    Shaka Manual Installer (TTY) for MacBookPro11,2 (Late 2013, 15" iGPU)
    Host: shaka-manual-installer    Target flake host: #shaka
    Mode: manual install only (NO automatic wipe / NO automatic nixos-install)
    Wi-Fi: auto-tries SSID "Pi" on boot; manual retry command: connect-pi
    Login as root, then run: help-install
  '';

  users.motd = ''
    ============================================================
    Shaka Manual Installer (TTY)
    ============================================================
    Wi-Fi auto-connect:
      SSID "Pi" will be attempted on boot (NetworkManager profile preset).
      Retry manually:      connect-pi
      Logs:                journalctl -u shaka-installer-autowifi -b --no-pager

    1. Connect network:  nmcli device status
    2. Confirm disk:     check-disk
    3. Review commands:  mount-plan
    4. Install:          install-shaka   (prints command only)
       Then:             install-shaka --run

    Full guide:
      /etc/nixos/flake/nixos-installer/README.md
  '';

  programs.bash.promptInit = ''
    if [[ -n "$PS1" ]]; then
      PS1='\[\e[1;36m\][shaka-manual-installer]\[\e[0m\] \[\e[1;33m\]\w\[\e[0m\] # '
    fi
  '';

  programs.bash.interactiveShellInit = ''
    if [[ -z "''${SHAKA_INSTALLER_HELP_SHOWN:-}" ]]; then
      export SHAKA_INSTALLER_HELP_SHOWN=1
      shaka-install-help || true
    fi
  '';
}
