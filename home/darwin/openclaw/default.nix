# OpenClaw 声明式配置（nix-openclaw）
# 未配置 Telegram，使用本地 WebChat/CLI；包与 PATH 包装见 lib/openclaw-package.nix
{ config, lib, pkgs, openclawPackageNoOracle, ... }:

let
  stateDir = "${config.home.homeDirectory}/.openclaw";
  configPath = "${stateDir}/openclaw.json";

  # 最小有效 config：单处定义，programs.openclaw.config 与 fallback JSON 共用
  openclawMinimalConfig = {
    gateway = {
      mode = "local";
      auth.token = "local-dev"; # 本地模式也需非空 token；生产可改为 secrets
    };
    agents = { defaults = { model = { primary = "openai/gpt-4o"; }; }; };
  };

  openclawConfigFallbackFile = pkgs.writeText "openclaw-fallback.json" (builtins.toJSON openclawMinimalConfig);
in
{
  programs.openclaw = {
    enable = true;
    package = openclawPackageNoOracle;
    documents = ./documents;

    config = openclawMinimalConfig;

    # 首方插件：截图、总结等（可选）
    firstParty = {
      summarize.enable = true;
      peekaboo.enable = true;
      oracle.enable = false;
      poltergeist.enable = false;
      sag.enable = false;
      camsnap.enable = false;
    };

    # 实例与 launchd（须在 programs.openclaw 下）
    instances.default = {
      enable = true;
      launchd.enable = true;
      plugins = [ ];
    };
  };

  # 若 nix-openclaw 生成的 openclaw.json 为空 {}，则用本配置写回最小有效 JSON（gateway 才能启动）
  home.activation.openclawConfigFallback = lib.hm.dag.entryAfter [ "openclawConfigFiles" ] ''
    if [ -f ${configPath} ] && [ "$(cat ${configPath} 2>/dev/null)" = "{}" ]; then
      rm -f ${configPath}
      ln -sfn ${openclawConfigFallbackFile} ${configPath}
      echo "openclaw: replaced empty config with fallback (gateway.mode=local)"
    fi
  '';
}
