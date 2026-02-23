{
  nixfmt = {
    enable = true;
    settings.width = 100;
  };

  typos = {
    enable = true;
    settings = {
      write = true;
      configPath = ".typos.toml";
      exclude = "rime-data/";
    };
  };

  prettier = {
    enable = true;
    settings = {
      write = true;
      configPath = ".prettierrc.yaml";
    };
  };

  # deadnix.enable = true;
  # statix.enable = true;
}
