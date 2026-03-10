{ ... }:
{
  # Disable macOS auto-update (check/download); install controlled below via SoftwareUpdate
  system.activationScripts.extraActivation.text = ''
    defaults write /Library/Preferences/com.apple.SoftwareUpdate.plist AutomaticCheckEnabled -bool false
    defaults write /Library/Preferences/com.apple.SoftwareUpdate.plist AutomaticDownload -bool false
    defaults write /Library/Preferences/com.apple.SoftwareUpdate.plist CriticalUpdateInstall -bool false
  '';
}
