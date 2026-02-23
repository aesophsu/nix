{ config, pkgs, ... }:
{
  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ahci"
    "nvme"
    "usb_storage"
    "usbhid"
    "sd_mod"
    "sdhci_pci"
  ];

  boot.kernelPackages = pkgs.linuxKernel.packages.linux_6_12;
  boot.kernelModules = [
    "wl"
    "applesmc"
    "coretemp"
    "thunderbolt"
    "intel_rapl_common"
    "kvm-intel"
  ];
  boot.extraModulePackages = [ config.boot.kernelPackages.broadcom_sta ];
  boot.blacklistedKernelModules = [
    "b43"
    "b43legacy"
    "bcma"
    "brcmsmac"
    "brcmfmac"
    "nouveau"
    "ssb"
  ];

  hardware.enableRedistributableFirmware = true;
  hardware.facetimehd.enable = true;
  hardware.facetimehd.withCalibration = false;
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
  hardware.cpu.intel.updateMicrocode = true;
}
