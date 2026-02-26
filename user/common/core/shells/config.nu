# Configure Nushell history settings
$env.config.history.file_format = "sqlite"  # Use SQLite for history storage
$env.config.history.max_size = 5_000_000  # Set maximum history size

# Isolation between multiple Nushell sessions
$env.config.history.isolation = true  # Prevent history from mixing across sessions

# Miscellaneous Settings
$env.config.show_banner = false  # Disable the welcome banner at startup
$env.config.rm.always_trash = true  # Always move files to trash instead of permanent deletion
$env.config.recursion_limit = 50  # Set the recursion limit for commands

# Commandline Editor Settings
$env.config.edit_mode = "vi"  # Use "vi" editing mode
$env.config.buffer_editor = ["nvim", "--clean"]  # Set editor for buffer with Ctrl+O

# Cursor shape settings for different modes
$env.config.cursor_shape.emacs = "inherit"  # Inherit terminal cursor shape in Emacs mode
$env.config.cursor_shape.vi_insert = "block"  # Block cursor in vi insert mode
$env.config.cursor_shape.vi_normal = "underscore"  # Underscore cursor in vi normal mode

# Terminal Integration Settings
$env.config.use_kitty_protocol = false  # Disable Kitty terminal protocol
$env.config.shell_integration.osc2 = true  # Show current directory and command in terminal tab
$env.config.shell_integration.osc7 = true  # Enable directory reporting to terminal
$env.config.shell_integration.osc9_9 = false  # Disable alternative directory reporting (OSC 9;9)
$env.config.shell_integration.osc8 = true  # Enable clickable links in `ls` output
$env.config.shell_integration.osc133 = true  # Enable OSC 133 for prompt and command status
$env.config.shell_integration.osc633 = true  # Enable OSC 633 for Visual Studio Code

# Plugin and script directories
const NU_LIB_DIRS = [
    ($nu.default-config-dir | path join 'scripts')  # Nushell scripts directory
    ($nu.data-dir | path join 'completions')  # Nushell completions directory
]

const NU_PLUGIN_DIRS = [
    ($nu.default-config-dir | path join 'plugins')  # Nushell plugins directory
]

# Add local bin to PATH for convenience
use std/util "path add"
path add "~/.local/bin"

# Remove duplicate directories from PATH
$env.PATH = ($env.PATH | uniq)
