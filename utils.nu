export def log [msg: string] {
  print $"[just] ($msg)"
}

export def host-name [] {
  (^hostname | str trim)
}

export def assert-non-empty [label: string, value: string] {
  if (($value | str trim) == "") {
    error make {msg: $"Missing required argument: ($label)"}
  }
}

export def git-dirty-warning [] {
  let dirty = (^git status --porcelain | str trim)
  if $dirty != "" {
    print "[just][warn] Git working tree has uncommitted changes."
  }
}

export def installer-flake-path [] {
  "./nixos-installer"
}
