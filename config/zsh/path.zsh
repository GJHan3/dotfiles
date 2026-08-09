typeset -gU path PATH

add_path_front() {
  local dir="$1"
  local entry
  local -a updated_path=("$dir")

  [[ -d "$dir" ]] || return

  for entry in "${path[@]}"; do
    [[ -n "$entry" && "$entry" != "$dir" ]] && updated_path+=("$entry")
  done

  path=("${updated_path[@]}")
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

load_homebrew_shellenv

if [[ -n "${HOMEBREW_PREFIX:-}" ]]; then
  add_path_front "$HOMEBREW_PREFIX/opt/curl/bin"
fi

add_path_front "$HOME/.local/bin"
add_path_front "$HOME/bin"
add_path_front "$HOME/.npm-global/bin"
add_path_front "$HOME/.local/share/pnpm"
add_path_front "$HOME/.cargo/bin"
add_path_front "$HOME/go/bin"
add_path_front "$HOME/.bun/bin"
