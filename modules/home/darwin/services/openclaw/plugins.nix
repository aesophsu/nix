{
  config,
  pkgs,
  ...
}:
let
  feishuPluginId = "feishu";
  memoryLancedbProId = "memory-lancedb-pro";
  memoryLancedbProVersion = "1.1.0-beta.6";
  memoryLancedbProRev = "cc8bf7cabc1b24c7769e15af59f41b49f43442b3";
  memoryLancedbProSrc = pkgs.fetchurl {
    url = "https://github.com/win4r/memory-lancedb-pro/archive/${memoryLancedbProRev}.tar.gz";
    hash = "sha256-W1aeASg6oxJ/pm88lZsf2j4kbbW1mCGycP4HGk9Yuuc=";
  };
  memoryLancedbProInstall = {
    source = "path";
    sourcePath = "${memoryLancedbProSrc}";
    installPath = "${config.home.homeDirectory}/.openclaw/extensions/${memoryLancedbProId}";
    version = memoryLancedbProVersion;
  };
  tavilyPluginId = "openclaw-tavily";
  tavilyPluginVersion = "0.2.1";
  tavilyPluginRev = "6db474508f44854864d6c47368c84962ef012120";
  tavilyPluginSrc = pkgs.fetchurl {
    url = "https://github.com/framix-team/openclaw-tavily/archive/${tavilyPluginRev}.tar.gz";
    hash = "sha256-GoveVFn+BSbQPFxYz9AZmhvV+hwJe6M+4YF+yc7sH5Q=";
  };
  tavilyPluginInstall = {
    source = "path";
    sourcePath = "${tavilyPluginSrc}";
    installPath = "${config.home.homeDirectory}/.openclaw/extensions/${tavilyPluginId}";
    version = tavilyPluginVersion;
  };
in
{
  _module.args.openclawPlugins = {
    inherit
      feishuPluginId
      memoryLancedbProId
      memoryLancedbProInstall
      memoryLancedbProSrc
      memoryLancedbProVersion
      tavilyPluginId
      tavilyPluginInstall
      tavilyPluginSrc
      tavilyPluginVersion
      ;
  };
}
