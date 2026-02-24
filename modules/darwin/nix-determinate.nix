{ lib, ... }:

{
  # Determinate Nix uses its own daemon; disable nix-darwin Nix management
  nix = {
    enable = false;
    settings.auto-optimise-store = false;
    # Disable transparent remote builder dispatch from local `nix build`.
    # NixOS ISO builds are done explicitly via the remote upload/build script.
    settings.builders = lib.mkForce "";
    extraOptions = "";
    gc.automatic = false;
  };

  # Determinate-managed nix-daemon still reads /etc/nix/machines at runtime.
  # Keep the file present but empty so runtime `builders` does not keep an old remote builder list.
  system.activationScripts.clearNixBuildersMachines.text = ''
    set -eu
    machines_file=/etc/nix/machines
    ts="$(date +%Y%m%d-%H%M%S)"

    if [ ! -e "$machines_file" ]; then
      touch "$machines_file"
      chown root:wheel "$machines_file"
      chmod 0644 "$machines_file"
      echo "[nix-determinate] created empty $machines_file"
    elif [ -s "$machines_file" ]; then
      cp "$machines_file" "$machines_file.bak-$ts"
      echo "[nix-determinate] backed up non-empty $machines_file to $machines_file.bak-$ts"
    fi

    : > "$machines_file"
    chown root:wheel "$machines_file"
    chmod 0644 "$machines_file"
    echo "[nix-determinate] cleared $machines_file"
  '';

  system.stateVersion = 5;
}
