{ config, lib, pkgs, rootSrc, ... }:
let
  # Embed the main repository flake, not this bootstrap subflake.
  flakeSource = rootSrc;
in
{
  imports = [
    (rootSrc + "/hosts/nixos-shaka/modules/common/networkmanager-default-wifi.nix")
  ];

  networking.hostName = "shaka-manual-installer";

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

  networking.networkmanager = {
    enable = lib.mkForce true;
    wifi.backend = "iwd";
  };
  networking.wireless.enable = lib.mkForce false;

  environment.systemPackages = with pkgs; [
    curl
    wget
    git
    tmux
    helix
    vim
    less
    file
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
    "nixos-macbookpro11-2-late2013-15-igpu-manual-installer-${config.system.nixos.label}-${pkgs.stdenv.hostPlatform.system}.iso";
  isoImage.volumeID = lib.mkForce "NIXOS_MBP112";
  isoImage.contents = [
    {
      source = flakeSource;
      target = "/etc/nixos/flake";
    }
  ];
}
