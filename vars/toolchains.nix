{
  go = {
    # Single source of truth for the Go toolchain used system-wide.
    package = "go";
  };

  node = {
    # Single source of truth for the stable Node.js major version.
    # Keep this pinned to an LTS major instead of tracking current/latest.
    package = "nodejs_22";
  };

  pnpm = {
    # Keep pnpm explicitly aligned with the OpenClaw ecosystem package set.
    package = "pnpm_10";
  };

  python = {
    # Single source of truth for the stable Python major/minor version.
    # Upgrade here only when you intentionally move the global interpreter.
    package = "python312";
  };
}
