{ ... }:
{
  xdg.configFile."kitty/kitty.conf".text = ''
    font_family      JetBrainsMono Nerd Font
    bold_font        auto
    italic_font      auto
    bold_italic_font auto
    font_size        13.0
    enable_audio_bell no
    confirm_os_window_close 0
    shell_integration enabled
    cursor_shape beam
    cursor_blink_interval 0.6

    background #303446
    foreground #c6d0f5
    selection_background #626880
    selection_foreground #c6d0f5
    url_color #8caaee
    cursor #f2d5cf

    color0  #51576d
    color1  #e78284
    color2  #a6d189
    color3  #e5c890
    color4  #8caaee
    color5  #f4b8e4
    color6  #81c8be
    color7  #b5bfe2
    color8  #626880
    color9  #e78284
    color10 #a6d189
    color11 #e5c890
    color12 #8caaee
    color13 #f4b8e4
    color14 #81c8be
    color15 #a5adce
  '';
}
