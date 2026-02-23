{ lib }:

let
  isNonEmptyString = v: builtins.isString v && v != "";
  isStringList = v: builtins.isList v && builtins.all builtins.isString v;
  isBool = v: builtins.isBool v;

  ensure = cond: msg: if cond then true else throw "host-registry: ${msg}";

  ensureOptional =
    pred: predName: host: field:
    if builtins.hasAttr field host then
      ensure (pred host.${field}) "host '${host.name or "<unknown>"}' field '${field}' must be ${predName}"
    else
      true;

  requiredField =
    host: field:
    ensure (builtins.hasAttr field host && isNonEmptyString host.${field}) "host missing/invalid required field '${field}'";

  normalizeHost =
    host:
    host
    // lib.optionalAttrs (!(host ? enabled)) { enabled = true; }
    // lib.optionalAttrs ((host.platform or "") == "darwin" && !(host ? homePath)) {
      homePath = "${host.hostPath}/home.nix";
    };

  validateHost =
    host:
    let
      checks = [
        (ensure (builtins.isAttrs host) "host entry must be an attrset")
        (requiredField host "name")
        (requiredField host "platform")
        (requiredField host "system")
        (requiredField host "hostPath")
        (ensure (builtins.elem host.platform [ "darwin" "nixos" ]) "host '${host.name}' has unsupported platform '${host.platform}'")
        (ensureOptional isNonEmptyString "a non-empty string" host "homePath")
        (ensureOptional isNonEmptyString "a non-empty string" host "kind")
        (ensureOptional isNonEmptyString "a non-empty string" host "profile")
        (ensureOptional isStringList "a list of strings" host "roles")
        (ensureOptional isStringList "a list of strings" host "tags")
        (ensureOptional isStringList "a list of strings" host "isoPackageAliases")
        (ensureOptional isBool "a bool" host "enabled")
        (
          ensure (
            if host.platform == "darwin" then
              lib.hasSuffix "-darwin" host.system
            else
              lib.hasSuffix "-linux" host.system
          ) "host '${host.name}' platform/system mismatch"
        )
        (
          if (host.kind or "") == "installer" then
            ensure (host.platform == "nixos") "installer host '${host.name}' must use platform=nixos"
          else
            true
        )
      ];
    in
    builtins.deepSeq checks (normalizeHost host);

  indexByName =
    hosts:
    builtins.listToAttrs (map (host: {
      name = host.name;
      value = host;
    }) hosts);

  listToSystemIndex =
    hosts:
    let
      systems = lib.unique (map (host: host.system) hosts);
    in
    builtins.listToAttrs (
      map (system: {
        name = system;
        value = builtins.filter (host: host.system == system) hosts;
      }) systems
    );

  mkPlatformIndex =
    platform: hosts:
    let
      allHosts = builtins.filter (host: host.platform == platform) hosts;
      enabledHosts = builtins.filter (host: host.enabled) allHosts;
    in
    {
      all = allHosts;
      enabled = enabledHosts;
      byName = indexByName enabledHosts;
      bySystem = listToSystemIndex enabledHosts;
      bySystemAll = listToSystemIndex allHosts;
    };

  validateRegistryImpl =
    registry:
    let
      checks = [
        (ensure (builtins.isAttrs registry) "registry must be an attrset")
        (ensure (builtins.hasAttr "hosts" registry) "registry must contain a 'hosts' field")
        (ensure (builtins.isList registry.hosts) "'hosts' must be a list")
      ];
      validatedHosts = map validateHost registry.hosts;
      names = map (host: host.name) validatedHosts;
      uniqueNames = lib.unique names;
      moreChecks = checks ++ [
        (ensure (builtins.length names == builtins.length uniqueNames) "duplicate host names are not allowed")
      ];
    in
    builtins.deepSeq moreChecks (registry // { hosts = validatedHosts; });

  indexRegistryImpl =
    registry:
    let
      valid = validateRegistryImpl registry;
      hosts = valid.hosts;
      enabledHosts = builtins.filter (host: host.enabled) hosts;
      allSystems = lib.unique (map (host: host.system) hosts);
    in
    {
      inherit hosts enabledHosts;
      byName = indexByName hosts;
      byNameEnabled = indexByName enabledHosts;
      byPlatform = {
        darwin = mkPlatformIndex "darwin" hosts;
        nixos = mkPlatformIndex "nixos" hosts;
      };
      bySystem = builtins.listToAttrs (
        map (system: {
          name = system;
          value = builtins.filter (host: host.system == system && host.enabled) hosts;
        }) allSystems
      );
    };
in
{
  validateRegistry = validateRegistryImpl;
  indexRegistry = indexRegistryImpl;

  hostsForPlatformSystem =
    registryIndex: platform: system:
    (((registryIndex.byPlatform or { }).${platform} or { }).bySystem or { }).${system} or [ ];

  hostsForSystem =
    registryIndex: system: (registryIndex.bySystem or { }).${system} or [ ];

  isInstallerHost = host: (host.kind or "") == "installer";

  mergeField =
    field: fragments:
    lib.attrsets.mergeAttrsList (map (it: it.${field} or { }) fragments);

  mkPerHostTests =
    {
      hosts,
      configurations,
      prefix,
      buildTests,
    }:
    lib.attrsets.mergeAttrsList (
      map (
        host:
        let
          present = builtins.hasAttr host.name configurations;
          cfg = if present then configurations.${host.name} else null;
          testPrefix = "${prefix}-${host.name}";
        in
        buildTests {
          inherit host present cfg testPrefix;
        }
      ) hosts
    );
}
