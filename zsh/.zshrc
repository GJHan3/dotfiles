# vim别名
alias vim="nvim"

export PATH="$HOME/.local/bin:$PATH"

if [[ -f "$HOME/.zsh.secrets" ]]; then
  source "$HOME/.zsh.secrets"
fi

case "$(uname -s)" in
  Darwin)
    export DOTFILES_OS="macos"
    ;;
  Linux)
    export DOTFILES_OS="linux"
    ;;
  *)
    export DOTFILES_OS="unknown"
    ;;
esac

if [[ "$DOTFILES_OS" == "linux" ]]; then
  if [[ -d /home/linuxbrew/.linuxbrew/bin ]]; then
    export PATH="/home/linuxbrew/.linuxbrew/bin:$PATH"
  elif [[ -d "$HOME/.linuxbrew/bin" ]]; then
    export PATH="$HOME/.linuxbrew/bin:$PATH"
  fi
fi

proxy_on() {
  export https_proxy=http://127.0.0.1:7897
  export http_proxy=http://127.0.0.1:7897
  export all_proxy=socks5://127.0.0.1:7897
  export HTTPS_PROXY="$https_proxy"
  export HTTP_PROXY="$http_proxy"
  export ALL_PROXY="$all_proxy"
  echo "proxy on: $http_proxy"
}

proxy_off() {
  unset https_proxy http_proxy all_proxy
  unset HTTPS_PROXY HTTP_PROXY ALL_PROXY
  echo "proxy off"
}

sshid() {
  emulate -L zsh

  local ssh_dir config_file pubkey target alias_name user host identity port confirm target_with_port key_choice
  local -a pubkeys

  ssh_dir="$HOME/.ssh"
  config_file="$ssh_dir/config"
  pubkeys=("$ssh_dir"/*.pub(N))

  if (( ${#pubkeys} == 0 )); then
    echo "No public keys found in $ssh_dir"
    return 1
  fi

  if (( ${#pubkeys} == 1 )); then
    pubkey="${pubkeys[1]}"
    echo "Using public key: $pubkey"
  else
    echo "Select public key:"
    local i=1
    for pubkey in "${pubkeys[@]}"; do
      echo "$i) $pubkey"
      ((i++))
    done

    read "key_choice?Select public key [1]: "
    key_choice="${key_choice:-1}"

    if [[ "$key_choice" != <-> ]] || (( key_choice < 1 || key_choice > ${#pubkeys} )); then
      echo "Invalid selection"
      return 1
    fi

    pubkey="${pubkeys[key_choice]}"
  fi

  read "target?Enter SSH target (user@host or host): "
  [[ -z "$target" ]] && return 1

  if [[ "$target" == *"@"* ]]; then
    user="${target%@*}"
    host="${target#*@}"
  else
    host="$target"
    read "user?Enter SSH user (optional): "
  fi

  read "port?Enter SSH port (optional): "
  read "alias_name?Enter host alias [$host]: "
  alias_name="${alias_name:-$host}"

  if [[ -n "$port" ]]; then
    target_with_port="$host"
  else
    target_with_port="$target"
  fi

  if [[ -n "$user" && "$target_with_port" != *"@"* ]]; then
    target_with_port="$user@$target_with_port"
  fi

  if [[ -n "$port" ]]; then
    ssh-copy-id -i "$pubkey" -p "$port" "$target_with_port" || return 1
  else
    ssh-copy-id -i "$pubkey" "$target_with_port" || return 1
  fi

  read "confirm?Write SSH config to ~/.ssh/config? [Y/n]: "
  if [[ "$confirm" == [Nn]* ]]; then
    return 0
  fi

  mkdir -p "$ssh_dir"
  touch "$config_file"

  if grep -Eq "^Host[[:space:]]+$alias_name([[:space:]]|$)" "$config_file"; then
    echo "Host $alias_name already exists in $config_file"
    return 1
  fi

  identity="${pubkey%.pub}"

  {
    echo ""
    echo "Host $alias_name"
    echo "  HostName $host"
    [[ -n "$user" ]] && echo "  User $user"
    [[ -n "$port" ]] && echo "  Port $port"
    echo "  IdentityFile $identity"
  } >> "$config_file"

  echo "Added $alias_name to $config_file"
}

y() {
  emulate -L zsh

  local tmp cwd
  if ! command -v yazi >/dev/null 2>&1; then
    echo "yazi is not installed"
    return 1
  fi

  if ! tmp="$(mktemp "${TMPDIR:-/tmp}/yazi-cwd.XXXXXX" 2>/dev/null)"; then
    tmp="$(mktemp -t yazi-cwd)"
  fi

  yazi "$@" --cwd-file="$tmp"

  if cwd="$(command cat -- "$tmp" 2>/dev/null)" && [[ -n "$cwd" && "$cwd" != "$PWD" ]]; then
    builtin cd -- "$cwd"
  fi

  rm -f -- "$tmp"
}

tn() {
  emulate -L zsh

  local session_name="${1:-}"
  if ! command -v tmux >/dev/null 2>&1; then
    echo "tmux is not installed"
    return 1
  fi

  if [[ -z "$session_name" ]]; then
    read "session_name?Enter session name: "
  fi

  if [[ -z "$session_name" ]]; then
    echo "Session name cannot be empty"
    return 1
  fi

  if tmux has-session -t "$session_name" 2>/dev/null; then
    echo "Session '$session_name' already exists. Attaching..."
    if [[ -n "${TMUX:-}" ]]; then
      tmux switch-client -t "$session_name"
    else
      tmux attach-session -t "$session_name"
    fi
  else
    echo "Creating new session: $session_name"
    if [[ -n "${TMUX:-}" ]]; then
      tmux new-session -d -s "$session_name"
      tmux switch-client -t "$session_name"
    else
      tmux new-session -s "$session_name"
    fi
  fi
}

ts() {
  emulate -L zsh

  local session
  if ! command -v tmux >/dev/null 2>&1; then
    echo "tmux is not installed"
    return 1
  fi
  if ! command -v fzf >/dev/null 2>&1; then
    echo "fzf is not installed"
    return 1
  fi

  session="$(
    tmux list-sessions -F "#{session_name}: #{session_windows} windows (created #{session_created_string})" 2>/dev/null |
      fzf --prompt="Select tmux session: " \
        --height=40% \
        --reverse \
        --border \
        --bind='tab:down,shift-tab:up' \
        --header="Tab/Shift-Tab or ↑↓ to navigate, Enter to select" |
      cut -d: -f1
  )"

  if [[ -n "$session" ]]; then
    if [[ -n "${TMUX:-}" ]]; then
      tmux switch-client -t "$session"
    else
      tmux attach-session -t "$session"
    fi
  fi
}

tk() {
  emulate -L zsh

  local sessions
  if ! command -v tmux >/dev/null 2>&1; then
    echo "tmux is not installed"
    return 1
  fi
  if ! command -v fzf >/dev/null 2>&1; then
    echo "fzf is not installed"
    return 1
  fi

  sessions="$(
    tmux list-sessions -F "#{session_name}: #{session_windows} windows (created #{session_created_string})" 2>/dev/null |
      fzf --multi \
        --prompt="Select sessions to kill: " \
        --height=40% \
        --reverse \
        --border \
        --bind='tab:toggle+down,shift-tab:toggle+up' \
        --header="Tab to select/deselect, Enter to confirm kill" |
      cut -d: -f1
  )"

  if [[ -n "$sessions" ]]; then
    local session
    while IFS= read -r session; do
      [[ -z "$session" ]] && continue
      echo "Killing session: $session"
      tmux kill-session -t "$session"
    done <<< "$sessions"
  fi
}

proxy_on

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(git)

POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true

if [[ -d "$ZSH" ]]; then
  source "$ZSH/oh-my-zsh.sh"
fi

if [[ -f "$HOME/.p10k.zsh" ]]; then
  source "$HOME/.p10k.zsh"
fi

if [[ -d "$HOME/.config/zsh/local" ]]; then
  for local_rc in "$HOME/.config/zsh/local"/*.zsh(N); do
    source "$local_rc"
  done
fi

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"
