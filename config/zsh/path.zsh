typeset -gU path PATH

add_path_front() {
  local dir="$1"

  [[ -d "$dir" ]] || return
  path=("$dir" $path)
}

load_homebrew_shellenv() {
  local brew_bin

  case "$(uname -s)" in
    Darwin)
      for brew_bin in /opt/homebrew/bin/brew /usr/local/bin/brew; do
        if [[ -x "$brew_bin" ]]; then
          eval "$("$brew_bin" shellenv zsh)"
          return
        fi
      done
      ;;
    Linux)
      for brew_bin in /home/linuxbrew/.linuxbrew/bin/brew "$HOME/.linuxbrew/bin/brew"; do
        if [[ -x "$brew_bin" ]]; then
          eval "$("$brew_bin" shellenv zsh)"
          return
        fi
      done
      ;;
  esac
}

load_npm_global_bin() {
  local npm_prefix

  command -v npm >/dev/null 2>&1 || return

  npm_prefix="$(npm config get prefix 2>/dev/null)"
  [[ -n "$npm_prefix" && "$npm_prefix" != "undefined" ]] || return

  add_path_front "$npm_prefix/bin"
}

load_homebrew_shellenv

add_path_front "$HOME/.local/bin"
add_path_front "$HOME/bin"
add_path_front "$HOME/.npm-global/bin"
add_path_front "$HOME/.local/share/pnpm"
add_path_front "$HOME/.cargo/bin"
add_path_front "$HOME/go/bin"
add_path_front "$HOME/.bun/bin"

load_npm_global_bin

# EPT Claude Code wrapper.
# Keep EPT first so programs launched from zsh, including cc-connect, resolve
# `claude` to ~/.ept/bin/claude instead of any npm-global Claude install.
add_path_front "$HOME/.ept/bin"

# Use the EPT-managed Claude wrapper directly. CLAUDE_PATH can force EPT/Claude
# tooling back to ~/.npm-global/bin/claude, which is not desired for cc-connect.
unset CLAUDE_PATH
