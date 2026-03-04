{
  myvars,
  proxyTools,
  ...
}:
let
  proxyPolicy = myvars.networking.proxy.policy;
in
{
  # Disable macOS auto-update (check/download); install controlled below via SoftwareUpdate
  system.activationScripts.extraActivation.text = ''
    defaults write /Library/Preferences/com.apple.SoftwareUpdate.plist AutomaticCheckEnabled -bool false
    defaults write /Library/Preferences/com.apple.SoftwareUpdate.plist AutomaticDownload -bool false
    defaults write /Library/Preferences/com.apple.SoftwareUpdate.plist CriticalUpdateInstall -bool false

    # System proxy default follows vars/networking/default.nix -> proxy.policy.systemDefault
    ${if proxyPolicy.systemDefault == "on" then "${proxyTools.on}/bin/proxy-on" else "${proxyTools.off}/bin/proxy-off"}
  '';
}
