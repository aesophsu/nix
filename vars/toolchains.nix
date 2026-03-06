{
  node = {
    # Single source of truth for the stable Node.js major version.
    # Keep this pinned to an LTS major instead of tracking current/latest.
    package = "nodejs_22";
  };

  python = {
    # Single source of truth for the stable Python major/minor version.
    # Upgrade here only when you intentionally move the global interpreter.
    package = "python312";
  };
}
