{ lib }:
let
  # Host networking (currently stella only)
  hostsAddr = {
    stella = {
      iface = "en0";
      ipv4 = "10.0.0.3"; # for reference; actual IP via DHCP
    };
  };
in
{
  inherit hostsAddr;
  # Interface: DHCP for IP
  hostsInterface = lib.attrsets.mapAttrs (_: val: {
    interfaces."${val.iface}" = {
      useDHCP = true;
      ipv4.addresses = [ ];
    };
  }) hostsAddr;
}
