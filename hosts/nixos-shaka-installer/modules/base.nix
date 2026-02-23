{ config, lib, pkgs, ... }:
{
  imports = [
    ../../nixos-shaka/modules/common/networkmanager-default-wifi.nix
  ];

  networking.hostName = "shaka-installer";

  nixpkgs.hostPlatform = "x86_64-linux";
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowInsecurePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "broadcom-sta"
    ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  time.timeZone = lib.mkDefault "America/Los_Angeles";
  i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";
  console.keyMap = lib.mkDefault "us";

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

  networking.networkmanager = {
    enable = lib.mkForce true;
    wifi.backend = "iwd";
  };
  networking.wireless.enable = lib.mkForce false;

  services.fwupd.enable = true;
  services.mbpfan.enable = true;
  services.thermald.enable = true;

  environment.systemPackages = with pkgs; [
    curl
    wget
    git
    tmux
    helix
    vim
    pciutils
    usbutils
    lm_sensors
    smartmontools
    nvme-cli
    parted
    gptfdisk
    dosfstools
    e2fsprogs
    btrfs-progs
    xfsprogs
    cryptsetup
    ntfs3g
    exfatprogs
    hfsprogs
    apfs-fuse
    iw
    iwd
    wirelesstools
    wpa_supplicant
    efibootmgr
    sbctl
    mesa-demos
  ];

  image.fileName =
    "nixos-macbookpro11-2-late2013-15-igpu-installer-${config.system.nixos.label}-${pkgs.stdenv.hostPlatform.system}.iso";
  isoImage.volumeID = lib.mkForce "NIXOS_MBP112";
}
