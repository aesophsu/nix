{ config, lib, pkgs, mylib, ... }:
let
  autoInstallScript = pkgs.writeShellScript "shaka-auto-install" ''
    set -euxo pipefail

    export PATH=${lib.makeBinPath (with pkgs; [
      coreutils
      gnugrep
      gawk
      util-linux
      parted
      dosfstools
      btrfs-progs
      cryptsetup
      findutils
      gnused
      nix
      nixos-install-tools
      systemd
    ])}

    log() {
      echo "[shaka-auto-install] $*" | tee -a /var/log/shaka-auto-install.log
    }

    mapfile -t candidates < <(
      lsblk -bdpno NAME,TYPE,SIZE,RM,TRAN | \
        awk '$2=="disk" && $4==0 && $3>900000000000 && $3<1100000000000 && $5!="usb" { print $1 }'
    )

    if [ "''${#candidates[@]}" -ne 1 ]; then
      log "Expected exactly one internal ~1TB disk, found: ''${#candidates[@]}"
      lsblk -dpno NAME,TYPE,SIZE,RM,TRAN,MODEL | tee -a /var/log/shaka-auto-install.log
      exit 1
    fi

    DISK="''${candidates[0]}"
    log "Using target disk: $DISK"

    case "$DISK" in
      *nvme*|*mmcblk*)
        P1="''${DISK}p1"
        P2="''${DISK}p2"
        P3="''${DISK}p3"
        ;;
      *)
        P1="''${DISK}1"
        P2="''${DISK}2"
        P3="''${DISK}3"
        ;;
    esac

    if blkid | grep -q 'LABEL="NIXOS_BTRFS"'; then
      log "Detected existing NIXOS_BTRFS label. Refusing to overwrite automatically."
      exit 1
    fi

    swapoff -a || true
    umount -R /mnt || true

    log "Wiping partition table and creating GPT layout"
    parted -s "$DISK" mklabel gpt
    parted -s "$DISK" mkpart ESP fat32 1MiB 1025MiB
    parted -s "$DISK" set 1 esp on
    parted -s "$DISK" name 1 ESP
    parted -s "$DISK" mkpart primary linux-swap 1025MiB 33793MiB
    parted -s "$DISK" name 2 NIXOS_SWAP
    parted -s "$DISK" mkpart primary btrfs 33793MiB 100%
    parted -s "$DISK" name 3 NIXOS_BTRFS_PART
    partprobe "$DISK"
    udevadm settle

    log "Creating filesystems"
    mkfs.fat -F 32 -n ESP "$P1"
    mkswap -L NIXOS_SWAP "$P2"
    mkfs.btrfs -f -L NIXOS_BTRFS "$P3"

    log "Creating Btrfs subvolumes"
    mount "$P3" /mnt
    btrfs subvolume create /mnt/@root
    btrfs subvolume create /mnt/@home
    btrfs subvolume create /mnt/@nix
    btrfs subvolume create /mnt/@log
    umount /mnt

    log "Mounting target filesystems"
    mount -o subvol=@root,compress=zstd:3,discard=async,noatime,ssd,space_cache=v2 "$P3" /mnt
    mkdir -p /mnt/{boot,home,nix,var/log}
    mount -o subvol=@home,compress=zstd:3,discard=async,noatime,ssd,space_cache=v2 "$P3" /mnt/home
    mount -o subvol=@nix,compress=zstd:3,discard=async,noatime,ssd,space_cache=v2 "$P3" /mnt/nix
    mount -o subvol=@log,compress=zstd:3,discard=async,noatime,ssd,space_cache=v2 "$P3" /mnt/var/log
    mount "$P1" /mnt/boot
    swapon "$P2"

    log "Installing NixOS (flake host: shaka / hostname: shaka)"
    nixos-install \
      --root /mnt \
      --no-root-passwd \
      --option accept-flake-config true \
      --flake /etc/nixos/flake#shaka

    log "Installation complete. Powering off in 20 seconds."
    sync
    sleep 20
    systemctl poweroff
  '';
in
{
  isoImage.contents = [
    {
      source = mylib.relativeToRoot ".";
      target = "/etc/nixos/flake";
    }
  ];

  systemd.services.shaka-auto-install = {
    description = "Automatic NixOS installation for Shaka";
    wantedBy = [ "multi-user.target" ];
    after = [
      "local-fs.target"
      "NetworkManager.service"
    ];
    path = with pkgs; [
      bash
      coreutils
      util-linux
      parted
      dosfstools
      btrfs-progs
      gnugrep
      gawk
      systemd
      nix
      nixos-install-tools
    ];
    serviceConfig = {
      Type = "oneshot";
      StandardOutput = "journal+console";
      StandardError = "journal+console";
      ExecStart = autoInstallScript;
    };
  };
}
