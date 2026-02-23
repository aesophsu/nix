{ ... }:
{
  xdg.dataFile."fcitx5/rime/default.custom.yaml".text = ''
    patch:
      schema_list:
        - schema: rime_ice
        - schema: double_pinyin_flypy
        # Add your Xiaohe shape/spelling schema id below after copying local schema files.
        # - schema: your_xiaohe_schema_id
      menu/page_size: 7
      switcher/hotkeys:
        - F4
      ascii_composer/good_old_caps_lock: true
  '';

  xdg.dataFile."fcitx5/rime/local/README.local.md".text = ''
    Put local Rime schema/dict/custom files here for Xiaohe customization.

    Suggested files (examples):
    - `*.schema.yaml`
    - `*.dict.yaml`
    - `*.custom.yaml`
    - custom user dictionaries / phrase tables

    This directory lives at:
    `~/.local/share/fcitx5/rime/local/`

    Then edit:
    `~/.local/share/fcitx5/rime/default.custom.yaml`
    and add your schema id to `schema_list`.
  '';
}
