# mihomo: package, config, launchd
# Runtime config precedence: config.local.yaml (worktree) > config.yaml > config.yaml.example

{
  config,
  lib,
  pkgs,
  mylib,
  ...
}:

let
  configDir = "${config.xdg.configHome}/mihomo";
  configTarget = "${configDir}/config.yaml";
  providersDir = "${configDir}/proxies";
  rawAirport1Provider = "${providersDir}/airport1.yaml";
  controlledAirport1Provider = "${providersDir}/airport1-controlled.yaml";
  rawAirport2Provider = "${providersDir}/airport2.yaml";
  airport1TransformScript = "${configDir}/transform_airport1_provider.rb";
  rubyExe = "/usr/bin/ruby";
  trackedConfigSource = mylib.firstExistingPathOr {
    candidates = [
      ./config.yaml
    ];
    default = ./config.yaml.example;
  };
  localConfigPath = "${config.home.homeDirectory}/nix/modules/home/darwin/services/mihomo/config.local.yaml";
  airport1TransformCommand = "${rubyExe} '${airport1TransformScript}' '${rawAirport1Provider}' '${controlledAirport1Provider}'";
in
{
  home.packages = [ pkgs.mihomo ];

  xdg.configFile."mihomo/transform_airport1_provider.rb" = {
    source = ./transform_airport1_provider.rb;
    executable = true;
  };

  home.activation.mihomoRuntimePrepare = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    run --quiet ${lib.getExe' pkgs.coreutils "mkdir"} -p "${configDir}" "${providersDir}"
    run --quiet ${lib.getExe' pkgs.coreutils "rm"} -f "${configTarget}"
    if [ -f "${localConfigPath}" ]; then
      run --quiet ${lib.getExe' pkgs.coreutils "ln"} -s "${localConfigPath}" "${configTarget}"
    else
      run --quiet ${lib.getExe' pkgs.coreutils "ln"} -s "${trackedConfigSource}" "${configTarget}"
    fi
    if [ -f "${rawAirport1Provider}" ]; then
      run --quiet ${rubyExe} "${airport1TransformScript}" "${rawAirport1Provider}" "${controlledAirport1Provider}"
    fi
  '';

}
