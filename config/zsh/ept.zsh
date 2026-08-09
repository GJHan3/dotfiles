# EPT-backed Claude wrapper policy.
# Keep EPT shims first, then repo-managed wrappers in ~/bin before npm-global
# installs such as native Claude Code.
add_path_front "$HOME/bin"
add_path_front "$HOME/.ept/bin"

# Wrapper-local path overrides are set by ~/bin/claude.
# Clear stale shell exports so EPT tooling does not bind to old native installs.
unset CLAUDE_PATH
unset OPENCODE_PATH
