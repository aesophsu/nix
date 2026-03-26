final: prev:

prev.lib.optionalAttrs prev.stdenv.hostPlatform.isDarwin {
  # nixpkgs-darwin fdc7b8f sets CGO_ENABLED=0 for direnv while its build still
  # uses -linkmode=external, which breaks the Darwin build. Drop that override
  # locally until upstream packaging is consistent again.
  direnv = prev.direnv.overrideAttrs (old: {
    env = builtins.removeAttrs (old.env or { }) [ "CGO_ENABLED" ];
  });
}
