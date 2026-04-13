# EPT Claude Code wrapper.
# Keep EPT first so programs launched from zsh, including cc-connect, resolve
# `claude` to ~/.ept/bin/claude instead of any npm-global Claude install.
add_path_front "$HOME/.ept/bin"

# Use the EPT-managed Claude wrapper directly. CLAUDE_PATH can force EPT/Claude
# tooling back to ~/.npm-global/bin/claude, which is not desired for cc-connect.
unset CLAUDE_PATH
