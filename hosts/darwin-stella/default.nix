{ myvars, ... }:

{
  networking.hostName = myvars.hostname;
  networking.computerName = myvars.hostname;
  networking.localHostName = myvars.hostname;
  system.defaults.smb.NetBIOSName = myvars.hostname;
}
