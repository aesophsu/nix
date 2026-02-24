{ pkgs, ... }:
let
  connectPiScript = pkgs.writeShellScriptBin "shaka-connect-pi" ''
    set -euo pipefail

    log() {
      printf '[shaka-connect-pi] %s\n' "$*"
    }

    if nmcli -t -f ACTIVE,SSID dev wifi list 2>/dev/null | grep -q '^yes:Pi$'; then
      log "SSID Pi is already active."
      exit 0
    fi

    if nmcli -t -f NAME connection show | grep -qx 'Pi'; then
      log "Bringing up existing NetworkManager connection profile: Pi"
      exec nmcli connection up Pi
    fi

    log "Connection profile Pi not found, creating temporary profile and connecting."
    exec nmcli dev wifi connect "Pi" password "zxcvbnm8"
  '';

  helpScript = pkgs.writeShellScriptBin "shaka-install-help" ''
    cat <<'EOF'
    ============================================================
      Shaka Manual Installer (TTY) - MacBookPro11,2 (Late 2013)
    ============================================================

    This ISO will NOT auto-partition or auto-install.
    You must confirm the target disk manually before running any write commands.
    The installer will try to auto-connect Wi-Fi SSID "Pi" on boot.

    Quick commands:
      help-install     Show this guide again
      check-disk       List disks/partitions with labels and transport info
      check-wifi       NetworkManager / Wi-Fi quick status
      connect-pi       Retry connecting to SSID Pi (password preset)
      mount-plan       Print example partition + Btrfs subvolume commands
      install-shaka    Print the nixos-install command (use --run to execute)

    Embedded flake:
      /etc/nixos/flake
      Install target: #shaka

    Read the full guide:
      /etc/nixos/flake/docs/NIXOS_SHAKA_INSTALL_MBP112.md

    Safety:
      - All destructive commands are shown as examples only.
      - Replace /dev/sdX with your confirmed internal disk device.
      - Double-check labels: ESP / NIXOS_SWAP / NIXOS_BTRFS.
      - Wi-Fi PSK for SSID Pi is stored in the installer Nix store by design.
    EOF
  '';

  mountPlanScript = pkgs.writeShellScriptBin "shaka-install-mount-plan" ''
    cat <<'EOF'
    # Example manual install plan (REVIEW AND EDIT DEVICE FIRST)
    export DISK=/dev/sdX
    # For nvme/mmc, partitions become p1/p2/p3; for sata they are 1/2/3.

    # 1) Inspect
    lsblk -dpno NAME,TYPE,SIZE,RM,TRAN,MODEL
    parted -l

    # 2) Partition (destructive)
    parted -s "$DISK" mklabel gpt
    parted -s "$DISK" mkpart ESP fat32 1MiB 1025MiB
    parted -s "$DISK" set 1 esp on
    parted -s "$DISK" name 1 ESP
    parted -s "$DISK" mkpart primary linux-swap 1025MiB 33793MiB
    parted -s "$DISK" name 2 NIXOS_SWAP
    parted -s "$DISK" mkpart primary btrfs 33793MiB 100%
    parted -s "$DISK" name 3 NIXOS_BTRFS_PART

    # 3) Derive partition names
    case "$DISK" in
      *nvme*|*mmcblk*) P1="''${DISK}p1"; P2="''${DISK}p2"; P3="''${DISK}p3" ;;
      *)               P1="''${DISK}1";  P2="''${DISK}2";  P3="''${DISK}3"  ;;
    esac

    # 4) Filesystems
    mkfs.fat -F 32 -n ESP "$P1"
    mkswap -L NIXOS_SWAP "$P2"
    mkfs.btrfs -f -L NIXOS_BTRFS "$P3"

    # 5) Btrfs subvolumes
    mount "$P3" /mnt
    btrfs subvolume create /mnt/@root
    btrfs subvolume create /mnt/@home
    btrfs subvolume create /mnt/@nix
    btrfs subvolume create /mnt/@log
    umount /mnt

    # 6) Mount layout (matches hosts/nixos-shaka/modules/common/storage-btrfs-hibernate.nix)
    mount -o subvol=@root,compress=zstd:3,discard=async,noatime,ssd,space_cache=v2 "$P3" /mnt
    mkdir -p /mnt/{boot,home,nix,var/log}
    mount -o subvol=@home,compress=zstd:3,discard=async,noatime,ssd,space_cache=v2 "$P3" /mnt/home
    mount -o subvol=@nix,compress=zstd:3,discard=async,noatime,ssd,space_cache=v2 "$P3" /mnt/nix
    mount -o subvol=@log,compress=zstd:3,discard=async,noatime,ssd,space_cache=v2 "$P3" /mnt/var/log
    mount "$P1" /mnt/boot
    swapon "$P2"

    # 7) Install (print first)
    install-shaka
    # install-shaka --run
    EOF
  '';

  installScript = pkgs.writeShellScriptBin "shaka-install-shaka" ''
    set -euo pipefail
    cmd=(nixos-install --root /mnt --no-root-passwd --option accept-flake-config true --flake /etc/nixos/flake#shaka)
    if [[ "''${1:-}" != "--run" ]]; then
      printf 'Planned install command (not executed):\n'
      printf '  %q ' "''${cmd[@]}"
      printf '\n\nUse `install-shaka --run` after confirming mounts and network.\n'
      exit 0
    fi

    printf 'About to execute:\n  %q ' "''${cmd[@]}"
    printf '\nType YES to continue: '
    read -r answer
    [[ "$answer" == "YES" ]] || {
      echo "Cancelled."
      exit 1
    }
    exec "''${cmd[@]}"
  '';
in
{
  environment.systemPackages = [
    connectPiScript
    helpScript
    mountPlanScript
    installScript
  ];

  environment.shellAliases = {
    "help-install" = "shaka-install-help";
    "check-disk" = "lsblk -dpno NAME,TYPE,SIZE,RM,TRAN,MODEL && echo && blkid || true";
    "check-wifi" = "nmcli device status; echo; nmcli -f ACTIVE,SSID,SIGNAL,SECURITY dev wifi list ifname wlan0 2>/dev/null || nmcli dev wifi list || true";
    "connect-pi" = "shaka-connect-pi";
    "mount-plan" = "shaka-install-mount-plan";
    "install-shaka" = "shaka-install-shaka";
  };

  systemd.services.shaka-installer-autowifi = {
    description = "Attempt automatic Wi-Fi connect to SSID Pi for installer";
    wantedBy = [ "multi-user.target" ];
    after = [
      "NetworkManager.service"
    ];
    wants = [
      "NetworkManager.service"
    ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash -lc '${connectPiScript}/bin/shaka-connect-pi || true'";
      RemainAfterExit = false;
      StandardOutput = "journal+console";
      StandardError = "journal+console";
    };
    path = with pkgs; [
      networkmanager
      gnugrep
      coreutils
    ];
  };
}
