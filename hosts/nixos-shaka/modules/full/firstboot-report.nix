{ pkgs, ... }:
{
  systemd.services.shaka-firstboot-report = {
    description = "Shaka first boot hardware and power report";
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
    after = [
      "multi-user.target"
      "network-online.target"
      "NetworkManager.service"
    ];
    path = with pkgs; [
      bash
      coreutils
      gnugrep
      gawk
      util-linux
      findutils
      btrfs-progs
      kmod
      iproute2
      lm_sensors
      acpi
      tlp
      networkmanager
      fwupd
      systemd
    ];
    serviceConfig = {
      Type = "oneshot";
      StateDirectory = "shaka";
      ConditionPathExists = "!/var/lib/shaka/first-boot.done";
    };
    script = ''
      set -euo pipefail

      out="/var/lib/shaka/first-boot-report.txt"
      stamp="/var/lib/shaka/first-boot.done"

      {
        echo "Shaka First Boot Report"
        echo "Generated: $(date -Is)"
        echo
        echo "== System =="
        uname -a || true
        uptime || true
        echo
        echo "== Hostname =="
        hostnamectl || true
        echo
        echo "== Block Devices =="
        lsblk -o NAME,SIZE,TYPE,FSTYPE,LABEL,PARTLABEL,MOUNTPOINTS || true
        echo
        echo "== Mounts =="
        findmnt -R / || true
        echo
        echo "== Swap =="
        swapon --show --bytes --output=NAME,TYPE,SIZE,USED,PRIO || true
        zramctl || true
        echo
        echo "== Memory =="
        free -h || true
        echo
        echo "== Btrfs =="
        btrfs filesystem usage -T / || true
        btrfs subvolume list / || true
        echo
        echo "== Power/Thermal =="
        systemctl --no-pager --full status tlp.service mbpfan.service thermald.service 2>/dev/null || true
        tlp-stat -s 2>/dev/null || true
        tlp-stat -b 2>/dev/null || true
        acpi -V 2>/dev/null || true
        sensors 2>/dev/null || true
        echo
        echo "== Graphics / Kernel Modules =="
        lsmod | grep -E '^(wl|facetimehd|i915|applesmc|kvm_intel)\\b' || true
        echo
        echo "== Network =="
        nmcli general status 2>/dev/null || true
        nmcli device status 2>/dev/null || true
        ip -brief address || true
        echo
        echo "== Timers =="
        systemctl list-timers --all --no-pager | grep -E 'btrfs|fstrim|nix-gc' || true
        echo
        echo "== fwupd =="
        fwupdmgr get-devices --no-unreported-check 2>/dev/null || true
      } > "$out"

      chmod 0600 "$out"
      touch "$stamp"
      echo "First boot report written to $out"
    '';
  };
}
