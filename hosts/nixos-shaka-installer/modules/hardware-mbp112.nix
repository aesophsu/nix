{ config, pkgs, ... }:
{
  hardware.enableRedistributableFirmware = true;
  hardware.facetimehd.enable = true;
  hardware.facetimehd.withCalibration = false;
  hardware.bluetooth.enable = true;
  hardware.graphics.enable = true;
  hardware.cpu.intel.updateMicrocode = true;

  boot.kernelPackages = pkgs.linuxKernel.packages.linux_6_12;
  boot.kernelModules = [
    "wl"
    "applesmc"
    "coretemp"
    "thunderbolt"
    "intel_rapl_common"
  ];
  boot.extraModulePackages = [ config.boot.kernelPackages.broadcom_sta ];
  boot.blacklistedKernelModules = [
    "b43"
    "b43legacy"
    "bcma"
    "brcmsmac"
    "brcmfmac"
    "ssb"
  ];

  services.fwupd.enable = true;
  services.mbpfan.enable = true;
  services.thermald.enable = true;
}
