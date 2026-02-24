# 在 MacBookPro11,2（Late 2013, 15" iGPU）上手动安装 `shaka`

适用于：

- 机型：`MacBookPro11,2`（MacBook Pro Retina 15" Late 2013，Intel 集显）
- 目标：安装本仓库 NixOS 主机 `.#shaka`
- 安装方式：使用仓库自带 `manual installer` ISO（手动分区、手动挂载、手动执行 `nixos-install`）

## 重要说明（不会自动抹盘）

当前 ISO 已移除“一键安装”与开机自动安装服务：

- 不会自动检测磁盘
- 不会自动分区 / 格式化
- 不会自动执行 `nixos-install`

你需要手动确认目标磁盘并执行安装命令。

安装器模块入口：

- `nixos-installer/flake.nix`
- `nixos-installer/hosts/shaka-mbp112-installer.nix`
- `nixos-installer/modules/install-helper.nix`
- `nixos-installer/modules/ui-tty.nix`

## 目标磁盘布局（与 `shaka` 配置对齐）

对应配置文件：

- `hosts/nixos-shaka/modules/common/storage-btrfs-hibernate.nix`

推荐布局（1TB SSD）：

- `ESP`：约 `1GiB`（FAT32）
- `NIXOS_SWAP`：约 `32GiB`（swap / hibernate）
- `NIXOS_BTRFS`：剩余空间（Btrfs）

Btrfs 子卷：

- `@root`
- `@home`
- `@nix`
- `@log`

## 1. 构建 manual installer ISO（推荐：macOS 上传到远程 Linux 构建）

在维护机（macOS）执行：

```bash
cd /Users/sue/Code/nix

# 先 dry-run（推荐）
nixos-installer/scripts/build-remote.sh --dry-run \
  --host <ssh-host> \
  --remote-dir <remote-dir>

# 实际构建并回传 ISO
nixos-installer/scripts/build-remote.sh \
  --host <ssh-host> \
  --remote-dir <remote-dir> \
  --iso shaka-manual-installer-iso
```

默认本地产物目录：

- `archive/iso-out/`

可用 ISO alias：

- `shaka-manual-installer-iso`
- `macbookpro11-2-manual-installer-iso`

如你有本地或远程 `x86_64-linux` 构建机，也可直接：

```bash
nix build ./nixos-installer#packages.x86_64-linux.shaka-manual-installer-iso
```

补充说明见：

- `docs/NIXOS_ISO_REMOTE_BUILD.md`

## 2. 将 ISO 写入 U 盘

推荐图形工具（更不容易选错盘）：

- `balenaEtcher`
- `Rufus`（Windows）

macOS 命令行写盘（请先确认目标磁盘号）：

```bash
diskutil list
diskutil unmountDisk /dev/diskN
sudo dd if=/Users/sue/Code/nix/archive/iso-out/<your-iso>.iso of=/dev/rdiskN bs=4m status=progress
sync
diskutil eject /dev/diskN
```

## 3. 在 MacBookPro11,2 从 U 盘启动

1. 插入 U 盘
2. 开机后立即按住 `Option (Alt)`
3. 在启动菜单选择 `EFI Boot`
4. 进入自定义 NixOS 手动安装器（TTY）
5. 登录 `root` 后先执行 `help-install`

## 4. 联网与环境确认（在 installer 中）

安装器启动后会自动尝试连接以下接入点（best effort，不会因失败中断安装流程）：

- SSID：`Pi`
- 密码：`zxcvbnm8`

如自动连接失败，可手动重试：

```bash
connect-pi
journalctl -u shaka-installer-autowifi -b --no-pager
```

查看网络与 Wi-Fi：

```bash
check-wifi
nmcli device status
nmcli dev wifi list
```

连接 Wi-Fi（示例）：

```bash
nmcli dev wifi connect "<SSID>" password "<PASSWORD>"
```

确认 `flake` 已内嵌：

```bash
ls /etc/nixos/flake
ls /etc/nixos/flake/nixos-installer
```

## 5. 手动确认目标磁盘（必须人工确认）

```bash
check-disk
# 或更详细
lsblk -dpno NAME,TYPE,SIZE,RM,TRAN,MODEL
parted -l
```

确认后记录目标磁盘，例如：

- SATA SSD：`/dev/sda`
- NVMe SSD：`/dev/nvme0n1`

## 6. 手动分区（会抹盘，请再次确认）

以下命令为示例，请先设置正确磁盘：

```bash
export DISK=/dev/sdX

parted -s "$DISK" mklabel gpt
parted -s "$DISK" mkpart ESP fat32 1MiB 1025MiB
parted -s "$DISK" set 1 esp on
parted -s "$DISK" name 1 ESP
parted -s "$DISK" mkpart primary linux-swap 1025MiB 33793MiB
parted -s "$DISK" name 2 NIXOS_SWAP
parted -s "$DISK" mkpart primary btrfs 33793MiB 100%
parted -s "$DISK" name 3 NIXOS_BTRFS_PART
```

根据设备类型设置分区变量：

```bash
case "$DISK" in
  *nvme*|*mmcblk*)
    P1="${DISK}p1"; P2="${DISK}p2"; P3="${DISK}p3"
    ;;
  *)
    P1="${DISK}1"; P2="${DISK}2"; P3="${DISK}3"
    ;;
esac
```

## 7. 格式化并创建 Btrfs 子卷

```bash
mkfs.fat -F 32 -n ESP "$P1"
mkswap -L NIXOS_SWAP "$P2"
mkfs.btrfs -f -L NIXOS_BTRFS "$P3"

mount "$P3" /mnt
btrfs subvolume create /mnt/@root
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@nix
btrfs subvolume create /mnt/@log
umount /mnt
```

## 8. 挂载目标文件系统（与 `shaka` 配置一致）

```bash
mount -o subvol=@root,compress=zstd:3,discard=async,noatime,ssd,space_cache=v2 "$P3" /mnt
mkdir -p /mnt/{boot,home,nix,var/log}
mount -o subvol=@home,compress=zstd:3,discard=async,noatime,ssd,space_cache=v2 "$P3" /mnt/home
mount -o subvol=@nix,compress=zstd:3,discard=async,noatime,ssd,space_cache=v2 "$P3" /mnt/nix
mount -o subvol=@log,compress=zstd:3,discard=async,noatime,ssd,space_cache=v2 "$P3" /mnt/var/log
mount "$P1" /mnt/boot
swapon "$P2"
```

可用辅助命令打印完整模板（仅打印，不执行）：

```bash
mount-plan
```

## 9. 执行 `nixos-install`

先查看安装命令（默认仅打印）：

```bash
install-shaka
```

确认挂载和网络都正确后执行：

```bash
install-shaka --run
```

等价命令（手动直接执行）：

```bash
nixos-install \
  --root /mnt \
  --no-root-passwd \
  --option accept-flake-config true \
  --flake /etc/nixos/flake#shaka
```

## 10. 安装完成后重启并从内置盘启动

```bash
sync
reboot
```

1. 拔掉 U 盘（或重启时按 `Option` 选择内置 `EFI`）
2. 进入已安装的 `shaka` 系统

## 11. 首次启动后的基础验证（必须做）

```bash
# 驱动模块（允许 grep 未命中时不报错）
lsmod | grep -E '^(wl|facetimehd|i915|applesmc|kvm_intel)\b' || true

# 电源/散热服务
systemctl --no-pager --full status tlp.service mbpfan.service thermald.service 2>/dev/null || true

# 网络状态
nmcli device status
```

人工检查：

- Wi-Fi 是否稳定联网
- 蓝牙是否能打开
- 亮度键 / 音量键是否可用
- 合盖睡眠、开盖唤醒是否正常
- 风扇是否异常高转

## 常见失败场景与处理（手动安装版）

### 1) 分区变量写错（`/dev/sdX1` vs `/dev/nvme0n1p1`）

症状：`mkfs` / `mount` 提示设备不存在。

处理：

- 重新 `echo "$DISK" "$P1" "$P2" "$P3"`
- 用 `lsblk` 确认分区命名规则
- NVMe / eMMC 设备使用 `p1/p2/p3`

### 2) `nixos-install` 报挂载点问题

排查：

```bash
mount | grep ' /mnt' || true
findmnt /mnt /mnt/boot /mnt/home /mnt/nix /mnt/var/log
```

处理：

- 确认 `/mnt/boot` 已挂载 `ESP`
- 确认 Btrfs 子卷名与配置一致：`@root/@home/@nix/@log`
- 确认 `swapon` 已执行（非必须安装成功，但建议）

### 3) `nixos-install` 无法访问 flake 路径

排查：

```bash
ls -la /etc/nixos/flake
ls -la /etc/nixos/flake/hosts
```

处理：

- 确认启动的是本仓库构建的自定义 ISO，而不是官方最小 ISO
- 重新写入最新 ISO 后再启动

### 4) 网络不通 / Wi-Fi 扫描不到

排查：

```bash
nmcli device status
journalctl -b -u NetworkManager --no-pager | tail -200
lsmod | grep '^wl\b' || true
```

处理：

- 先尝试重启 NetworkManager：`systemctl restart NetworkManager`
- 重新扫描：`nmcli dev wifi rescan && nmcli dev wifi list`
- 确认是否使用了正确的自定义 ISO（包含 Broadcom `wl` 支持）

## 安装验收清单

### 安装链路验收

1. ISO 构建成功（本地拿到 `.iso` 文件）
2. U 盘启动成功（进入手动安装器 TTY）
3. 手动分区/挂载成功（`findmnt` 检查通过）
4. `nixos-install` 成功完成
5. 重启后能从内置盘启动

### 首次启动功能验收

1. `wl` 驱动已加载且 Wi-Fi 可联网
2. `i915` 图形正常，桌面可用
3. `mbpfan` / `thermald` 服务正常运行
4. 合盖睡眠/唤醒至少成功一次

## 假设与默认值

- 目标机器：`MacBookPro11,2`（Late 2013, 15", Intel iGPU）
- 内置盘：约 `1TB`（本文示例按整盘重装流程编写）
- 安装目标：本仓库 flake 主机 `.#shaka`
- 安装方式：手动安装（非自动分区/非自动安装）
- 推荐构建路径：从 macOS 使用 `nixos-installer/scripts/build-remote.sh`（或 `scripts/iso/build-remote.sh --flake-subpath nixos-installer`）上传到远程 Linux 构建并回传 ISO
