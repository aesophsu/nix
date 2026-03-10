{ ... }:

{
  xdg.configFile."ghostty/config".text = ''
    # MacBook Air M4: prioritize a native macOS terminal look with minimal visual noise.
    font-family = SF Mono
    font-size = 11

    theme = light:GitHub Light Default,dark:Catppuccin Mocha

    window-padding-x = 10
    window-padding-y = 10
    background-opacity = 0.97

    cursor-style = block
    cursor-style-blink = false
    mouse-hide-while-typing = true
    scrollback-limit = 20000000

    macos-option-as-alt = left
    macos-titlebar-style = tabs
    window-save-state = always
    copy-on-select = clipboard
    confirm-close-surface = false
  '';
}
