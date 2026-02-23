{ ... }:
{
  xdg.configFile."niri/config.kdl".text = ''
    input {
        keyboard { xkb {} numlock }
        touchpad { tap dwt natural-scroll }
    }

    layout {
        gaps 12
        center-focused-column "on-overflow"
        default-column-width { proportion 0.58; }
        focus-ring {
            width 3
            active-color "#8caaee"
            inactive-color "#626880"
        }
        border {
            width 1
            active-color "#8caaee"
            inactive-color "#51576d"
        }
    }

    hotkey-overlay { skip-at-startup }
    prefer-no-csd
    screenshot-path "~/Pictures/Screenshots/Screenshot %Y-%m-%d %H-%M-%S.png"

    spawn-at-startup "waybar"
    spawn-at-startup "nm-applet" "--indicator"
    spawn-at-startup "fcitx5" "-d"

    window-rule {
        match app-id=r#"^mpv$"#
        open-floating true
    }

    binds {
        Mod+Return { spawn "kitty"; }
        Mod+Space  { spawn "fuzzel"; }
        Mod+E      { spawn "thunar"; }
        Mod+B      { spawn "google-chrome-stable"; }
        Mod+Q repeat=false { close-window; }
        Mod+Shift+Q { quit; }
        Super+Alt+L { spawn "swaylock"; }

        XF86AudioRaiseVolume allow-when-locked=true { spawn-sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.05+ -l 1.0"; }
        XF86AudioLowerVolume allow-when-locked=true { spawn-sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.05-"; }
        XF86AudioMute        allow-when-locked=true { spawn-sh "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"; }
        XF86AudioPlay        allow-when-locked=true { spawn-sh "playerctl play-pause"; }
        XF86AudioPrev        allow-when-locked=true { spawn-sh "playerctl previous"; }
        XF86AudioNext        allow-when-locked=true { spawn-sh "playerctl next"; }
        XF86MonBrightnessUp allow-when-locked=true { spawn "brightnessctl" "--class=backlight" "set" "+10%"; }
        XF86MonBrightnessDown allow-when-locked=true { spawn "brightnessctl" "--class=backlight" "set" "10%-"; }

        Mod+H { focus-column-left; }
        Mod+L { focus-column-right; }
        Mod+J { focus-window-down; }
        Mod+K { focus-window-up; }
        Mod+Ctrl+H { move-column-left; }
        Mod+Ctrl+L { move-column-right; }
        Mod+Ctrl+J { move-window-down; }
        Mod+Ctrl+K { move-window-up; }

        Mod+Tab { focus-workspace-previous; }
        Mod+1 { focus-workspace 1; }
        Mod+2 { focus-workspace 2; }
        Mod+3 { focus-workspace 3; }
        Mod+4 { focus-workspace 4; }
        Mod+5 { focus-workspace 5; }
        Mod+6 { focus-workspace 6; }
        Mod+7 { focus-workspace 7; }
        Mod+8 { focus-workspace 8; }
        Mod+9 { focus-workspace 9; }
        Mod+Ctrl+1 { move-column-to-workspace 1; }
        Mod+Ctrl+2 { move-column-to-workspace 2; }
        Mod+Ctrl+3 { move-column-to-workspace 3; }
        Mod+Ctrl+4 { move-column-to-workspace 4; }
        Mod+Ctrl+5 { move-column-to-workspace 5; }
        Mod+Ctrl+6 { move-column-to-workspace 6; }
        Mod+Ctrl+7 { move-column-to-workspace 7; }
        Mod+Ctrl+8 { move-column-to-workspace 8; }
        Mod+Ctrl+9 { move-column-to-workspace 9; }

        Mod+F { maximize-column; }
        Mod+Shift+F { fullscreen-window; }
        Mod+V { toggle-window-floating; }
        Mod+O repeat=false { toggle-overview; }

        Print { screenshot; }
        Ctrl+Print { screenshot-screen; }
        Alt+Print { screenshot-window; }
    }
  '';
}
