{ ... }:
{
  # Final disk layout (1TB SSD, GPT):
  #   p1: 1GiB  FAT32  label=ESP
  #   p2: 32GiB swap   partlabel=NIXOS_SWAP   (dedicated hibernate target)
  #   p3: rest  Btrfs  label=NIXOS_BTRFS      (subvolumes below)
  # Required Btrfs subvolumes: @root, @home, @nix, @log
  boot.supportedFilesystems = [ "btrfs" ];

  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXOS_BTRFS";
    fsType = "btrfs";
    options = [
      "subvol=@root"
      "compress=zstd:3"
      "discard=async"
      "noatime"
      "ssd"
      "space_cache=v2"
    ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/ESP";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  fileSystems."/home" = {
    device = "/dev/disk/by-label/NIXOS_BTRFS";
    fsType = "btrfs";
    options = [
      "subvol=@home"
      "compress=zstd:3"
      "discard=async"
      "noatime"
      "ssd"
      "space_cache=v2"
    ];
  };

  fileSystems."/nix" = {
    device = "/dev/disk/by-label/NIXOS_BTRFS";
    fsType = "btrfs";
    options = [
      "subvol=@nix"
      "compress=zstd:3"
      "discard=async"
      "noatime"
      "ssd"
      "space_cache=v2"
    ];
  };

  fileSystems."/var/log" = {
    device = "/dev/disk/by-label/NIXOS_BTRFS";
    fsType = "btrfs";
    options = [
      "subvol=@log"
      "compress=zstd:3"
      "discard=async"
      "noatime"
      "ssd"
      "space_cache=v2"
    ];
    neededForBoot = true;
  };

  swapDevices = [
    {
      device = "/dev/disk/by-partlabel/NIXOS_SWAP";
      priority = 0;
      discardPolicy = "once";
    }
  ];

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
    efi.efiSysMountPoint = "/boot";
    systemd-boot.configurationLimit = 10;
  };

  boot.resumeDevice = "/dev/disk/by-partlabel/NIXOS_SWAP";
  boot.kernelParams = [ "mem_sleep_default=deep" ];
}
