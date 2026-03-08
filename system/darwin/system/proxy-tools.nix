{
  pkgs,
  lib,
  myvars,
  ...
}:
let
  inherit (myvars.networking.mihomo) host httpPort socksPort httpProxy socksProxy;
  proxyCfg = myvars.networking.proxy;
  proxyPolicy = proxyCfg.policy;
  proxyServices = proxyCfg.systemServices;
  proxyServicesArray = lib.concatMapStringsSep "\n" (svc: "  \"${svc}\"") proxyServices;
  proxyEnv = proxyCfg.env { inherit httpProxy socksProxy; };
  proxyEnvExportScript = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (name: value: "printf 'export %s=%s\\n' ${lib.escapeShellArg name} ${lib.escapeShellArg value}") proxyEnv
  );
  proxyEnvVars = lib.concatStringsSep " " (builtins.attrNames proxyEnv);

  proxyOn = pkgs.writeShellScriptBin "proxy-on" ''
    set -euo pipefail

    services=(
${proxyServicesArray}
    )

    for svc in "''${services[@]}"; do
      if networksetup -listallnetworkservices 2>/dev/null | grep -q "^''${svc}$"; then
        networksetup -setwebproxy "''${svc}" ${host} ${httpPort} 2>/dev/null || true
        networksetup -setsecurewebproxy "''${svc}" ${host} ${httpPort} 2>/dev/null || true
        networksetup -setsocksfirewallproxy "''${svc}" ${host} ${socksPort} 2>/dev/null || true
        networksetup -setwebproxystate "''${svc}" on 2>/dev/null || true
        networksetup -setsecurewebproxystate "''${svc}" on 2>/dev/null || true
        networksetup -setsocksfirewallproxystate "''${svc}" on 2>/dev/null || true
      fi
    done
  '';

  proxyOff = pkgs.writeShellScriptBin "proxy-off" ''
    set -euo pipefail

    services=(
${proxyServicesArray}
    )

    for svc in "''${services[@]}"; do
      if networksetup -listallnetworkservices 2>/dev/null | grep -q "^''${svc}$"; then
        networksetup -setwebproxystate "''${svc}" off 2>/dev/null || true
        networksetup -setsecurewebproxystate "''${svc}" off 2>/dev/null || true
        networksetup -setsocksfirewallproxystate "''${svc}" off 2>/dev/null || true
      fi
    done
  '';

  proxyStatus = pkgs.writeShellScriptBin "proxy-status" ''
    set -euo pipefail

    services=(
${proxyServicesArray}
    )

    for svc in "''${services[@]}"; do
      if networksetup -listallnetworkservices 2>/dev/null | grep -q "^''${svc}$"; then
        echo "== $svc =="
        networksetup -getwebproxy "''${svc}" 2>/dev/null || true
        networksetup -getsecurewebproxy "''${svc}" 2>/dev/null || true
        networksetup -getsocksfirewallproxy "''${svc}" 2>/dev/null || true
        echo
      fi
    done
  '';

  proxyEnvOn = pkgs.writeShellScriptBin "proxy-env-on" ''
    set -euo pipefail

${proxyEnvExportScript}
  '';

  proxyEnvOff = pkgs.writeShellScriptBin "proxy-env-off" ''
    set -euo pipefail

    printf 'unset %s\n' "${proxyEnvVars}"
  '';

  proxyEnvStatus = pkgs.writeShellScriptBin "proxy-env-status" ''
    set -euo pipefail

    for name in ${proxyEnvVars}; do
      value="''${!name-}"
      if [ -n "''${value}" ]; then
        printf '%s=%s\n' "$name" "$value"
      fi
    done
  '';
in
{
  assertions = [
    {
      assertion = builtins.elem proxyPolicy.systemDefault [
        "on"
        "off"
      ];
      message = "myvars.networking.proxy.policy.systemDefault must be \"on\" or \"off\"";
    }
    {
      assertion = builtins.elem proxyPolicy.cliDefault [
        "on"
        "off"
      ];
      message = "myvars.networking.proxy.policy.cliDefault must be \"on\" or \"off\"";
    }
  ];

  environment.systemPackages = [
    proxyOn
    proxyOff
    proxyStatus
    proxyEnvOn
    proxyEnvOff
    proxyEnvStatus
  ];

  _module.args.proxyTools = {
    on = proxyOn;
    off = proxyOff;
    status = proxyStatus;
    envOn = proxyEnvOn;
    envOff = proxyEnvOff;
    envStatus = proxyEnvStatus;
  };
}
