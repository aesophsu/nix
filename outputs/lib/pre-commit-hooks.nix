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

  detect-private-keys.enable = true;

  check-added-large-files.enable = true;

  end-of-file-fixer.enable = true;

  shellcheck = {
    enable = true;
    files = "\\.sh$";
  };

  # deadnix.enable = true;
  # statix.enable = true;
}
