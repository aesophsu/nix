{
  pkgs,
  lib,
  myvars,
  ...
}:

let
  inherit (myvars.networking.mihomo) httpPort socksPort;
  inherit (myvars.networking.mihomo) host;
  proxyCfg = myvars.networking.proxy;
  proxyPolicy = proxyCfg.policy;
  proxyServices = proxyCfg.systemServices;
  proxyServicesArray = lib.concatMapStringsSep "\n" (svc: "  \"${svc}\"") proxyServices;

  proxyOn = pkgs.writeShellScriptBin "proxy-on" ''
    set -euo pipefail

    services=(
${proxyServicesArray}
    )

    for svc in "''${services[@]}"; do
      if networksetup -listallnetworkservices 2>/dev/null | grep -q "^''${svc}$"; then
        networksetup -setwebproxy "''${svc}" ${host} ${httpPort} 2>/dev/null || true
        networksetup -setsecurewebproxy "''${svc}" ${host} ${httpPort} 2>/dev/null || true
        networksetup -setsocksfirewallproxy "''${svc}" ${host} ${socksPort} 2>/dev/null || true
        networksetup -setwebproxystate "''${svc}" on 2>/dev/null || true
        networksetup -setsecurewebproxystate "''${svc}" on 2>/dev/null || true
        networksetup -setsocksfirewallproxystate "''${svc}" on 2>/dev/null || true
      fi
    done
  '';

  proxyOff = pkgs.writeShellScriptBin "proxy-off" ''
    set -euo pipefail

    services=(
${proxyServicesArray}
    )

    for svc in "''${services[@]}"; do
      if networksetup -listallnetworkservices 2>/dev/null | grep -q "^''${svc}$"; then
        networksetup -setwebproxystate "''${svc}" off 2>/dev/null || true
        networksetup -setsecurewebproxystate "''${svc}" off 2>/dev/null || true
        networksetup -setsocksfirewallproxystate "''${svc}" off 2>/dev/null || true
      fi
    done
  '';

  proxyStatus = pkgs.writeShellScriptBin "proxy-status" ''
    set -euo pipefail

    services=(
${proxyServicesArray}
    )

    for svc in "''${services[@]}"; do
      if networksetup -listallnetworkservices 2>/dev/null | grep -q "^''${svc}$"; then
        echo "== $svc =="
        networksetup -getwebproxy "''${svc}" 2>/dev/null || true
        networksetup -getsecurewebproxy "''${svc}" 2>/dev/null || true
        networksetup -getsocksfirewallproxy "''${svc}" 2>/dev/null || true
        echo
      fi
    done
  '';
in

{
  assertions = [
    {
      assertion = builtins.elem proxyPolicy.systemDefault [
        "on"
        "off"
      ];
      message = "myvars.networking.proxy.policy.systemDefault must be \"on\" or \"off\"";
    }
    {
      assertion = builtins.elem proxyPolicy.cliDefault [
        "on"
        "off"
      ];
      message = "myvars.networking.proxy.policy.cliDefault must be \"on\" or \"off\"";
    }
  ];

  environment.systemPackages = [
    proxyOn
    proxyOff
    proxyStatus
  ];

  security.pam.services.sudo_local.touchIdAuth = true;

  # Disable macOS auto-update (check/download); install controlled below via SoftwareUpdate
  system.activationScripts.extraActivation.text = ''
    defaults write /Library/Preferences/com.apple.SoftwareUpdate.plist AutomaticCheckEnabled -bool false
    defaults write /Library/Preferences/com.apple.SoftwareUpdate.plist AutomaticDownload -bool false
    defaults write /Library/Preferences/com.apple.SoftwareUpdate.plist CriticalUpdateInstall -bool false

    # System proxy default follows vars/networking.nix -> proxy.policy.systemDefault
    ${if proxyPolicy.systemDefault == "on" then "${proxyOn}/bin/proxy-on" else "${proxyOff}/bin/proxy-off"}
  '';

  time.timeZone = "Asia/Shanghai";

  system = {
    primaryUser = myvars.username;

    defaults = {
      # Disable macOS auto-update (check, download, install)
      SoftwareUpdate.AutomaticallyInstallMacOSUpdates = false;

      dock = {
        autohide = false;
        show-recents = false;
        mru-spaces = false;
      };

      finder = {
        _FXShowPosixPathInTitle = true;
        AppleShowAllExtensions = true;
        FXEnableExtensionChangeWarning = false;
        ShowPathbar = true;
        ShowStatusBar = true;
      };

      trackpad.Clicking = true;

      NSGlobalDomain = {
        AppleInterfaceStyle = "Dark";
        InitialKeyRepeat = 15;
        KeyRepeat = 3;
        ApplePressAndHoldEnabled = false;
      };
    };

    keyboard = {
      enableKeyMapping = true;
      remapCapsLockToEscape = false;
    };
  };
}
