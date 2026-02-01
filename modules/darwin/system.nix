{ pkgs, myvars, ... }:

let
  inherit (myvars.networking.mihomo) httpPort socksPort;
in

{
  security.pam.services.sudo_local.touchIdAuth = true;

  # 关闭 macOS 自动更新（检查、下载）
  # AutomaticallyInstallMacOSUpdates 由 system.defaults.SoftwareUpdate 处理
  system.activationScripts.extraActivation.text = ''
    # 禁用自动检查更新
    defaults write /Library/Preferences/com.apple.SoftwareUpdate.plist AutomaticCheckEnabled -bool false
    # 禁用后台自动下载
    defaults write /Library/Preferences/com.apple.SoftwareUpdate.plist AutomaticDownload -bool false
    # 禁用关键更新自动安装
    defaults write /Library/Preferences/com.apple.SoftwareUpdate.plist CriticalUpdateInstall -bool false

    # 设置 mihomo 为 macOS 系统默认代理（HTTP/HTTPS/SOCKS5）
    for svc in Wi-Fi Ethernet "USB 10/100/1000 LAN" "Thunderbolt Ethernet"; do
      if networksetup -listallnetworkservices 2>/dev/null | grep -q "^''${svc}$"; then
        networksetup -setwebproxy "''${svc}" 127.0.0.1 ${httpPort} 2>/dev/null || true
        networksetup -setsecurewebproxy "''${svc}" 127.0.0.1 ${httpPort} 2>/dev/null || true
        networksetup -setsocksfirewallproxy "''${svc}" 127.0.0.1 ${socksPort} 2>/dev/null || true
        networksetup -setwebproxystate "''${svc}" on 2>/dev/null || true
        networksetup -setsecurewebproxystate "''${svc}" on 2>/dev/null || true
        networksetup -setsocksfirewallproxystate "''${svc}" on 2>/dev/null || true
      fi
    done
  '';

  time.timeZone = "Asia/Shanghai";

  system = {
    primaryUser = myvars.username;

    defaults = {
      # 关闭 macOS 自动更新（检查、下载、安装）
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
