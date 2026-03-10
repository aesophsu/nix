{ lib }:
let
  hostsAddr = {
    stella = {
      iface = "en0";
      ipv4 = "10.0.0.3";
    };
  };
in
{
  inherit hostsAddr;
  hostsInterface = lib.attrsets.mapAttrs (_: val: {
    interfaces."${val.iface}" = {
      useDHCP = true;
      ipv4.addresses = [ ];
    };
  }) hostsAddr;
}
