# vim别名
alias vim="nvim"

if [[ -f "$HOME/.config/zsh/path.zsh" ]]; then
  source "$HOME/.config/zsh/path.zsh"
fi

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

_dotfiles_real_home() {
  emulate -L zsh

  local real_home=""

  if command -v getent >/dev/null 2>&1; then
    real_home="$(getent passwd "$USER" 2>/dev/null | cut -d: -f6)"
  elif [[ "$DOTFILES_OS" == "macos" ]] && command -v dscl >/dev/null 2>&1; then
    real_home="$(dscl . -read "/Users/$USER" NFSHomeDirectory 2>/dev/null | awk '{print $2}')"
  fi

  if [[ -z "$real_home" ]]; then
    real_home="$HOME"
  fi

  printf "%s" "$real_home"
}

_dotfiles_fix_xauthority() {
  emulate -L zsh

  local real_home xauthority_source

  [[ -n "${DISPLAY:-}" ]] || return 0

  real_home="$(_dotfiles_real_home)"
  xauthority_source="${real_home}/.Xauthority"

  if [[ -z "${XAUTHORITY:-}" && -f "$xauthority_source" ]]; then
    export XAUTHORITY="$xauthority_source"
  fi
}

_dotfiles_fix_xauthority

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

typeset -g SSHFS_MOUNT_ROOT="$HOME/sshmnt"
typeset -g SSHFS_MOUNT_OPTIONS="defer_permissions,reconnect,ServerAliveInterval=15,ServerAliveCountMax=3,idmap=user"

sshhosts() {
  emulate -L zsh

  local config
  local -a configs
  configs=("$HOME/.ssh/config" "$HOME/.ssh/config.d"/*(.N))

  awk '
    tolower($1) == "host" {
      for (i = 2; i <= NF; i++) {
        if ($i !~ /[*?!]/) print $i
      }
    }
  ' "${configs[@]}" 2>/dev/null | sort -u
}

_sshfs_select_host() {
  emulate -L zsh

  if ! command -v fzf >/dev/null 2>&1; then
    echo "fzf is not installed" >&2
    return 1
  fi

  sshhosts | fzf \
    --prompt="Select SSH host: " \
    --height=40% \
    --reverse \
    --border \
    --bind='tab:down,shift-tab:up' \
    --header="Hosts from ~/.ssh/config"
}

_sshfs_mount_dir() {
  emulate -L zsh

  local host="$1"
  local remote_path="$2"
  local cleaned_path base_name

  cleaned_path="${remote_path%/}"
  if [[ -z "$cleaned_path" || "$cleaned_path" == "/" ]]; then
    base_name="root"
  elif [[ "$cleaned_path" == "~" || "$cleaned_path" == "~/" ]]; then
    base_name="home"
  else
    base_name="${cleaned_path:t}"
  fi

  printf "%s/%s-%s" "$SSHFS_MOUNT_ROOT" "$host" "$base_name"
}

_sshfs_select_remote_path() {
  emulate -L zsh

  local host="$1"
  local seed="${2:-~}"
  local current_path
  local remote_home
  local selected_path

  if ! command -v fzf >/dev/null 2>&1; then
    printf "%s" "$seed"
    return 0
  fi

  remote_home="$(ssh "$host" "printf '%s' \"\$HOME\"" 2>/dev/null)"
  [[ -z "$remote_home" ]] && remote_home="/"

  case "$seed" in
    "~")
      current_path="$remote_home"
      ;;
    "~/"*)
      current_path="${remote_home}/${seed#~/}"
      ;;
    *)
      current_path="$seed"
      ;;
  esac

  while true; do
    selected_path="$(
      {
        printf './ [use %s]\n' "$current_path"
        if [[ "$current_path" != "/" ]]; then
          printf '../\n'
        fi
        ssh "$host" "sh -lc '
          current=\${1:-/}
          [ -d \"\$current\" ] || exit 0
          find -L \"\$current\" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; 2>/dev/null | sort -u
        ' sh $(printf '%q' "$current_path")" 2>/dev/null
      } | fzf \
        --prompt="Select remote dir> " \
        --height=50% \
        --reverse \
        --border \
        --layout=reverse-list \
        --no-sort \
        --header=$'Current remote path: '"$current_path"$'\nEnter on a directory: go into it\nEnter on ./: use current directory\nEnter on ../: go to parent directory'
    )"

    if [[ -z "$selected_path" || "$selected_path" == "./ [use $current_path]" ]]; then
      printf "%s" "$current_path"
      return 0
    fi

    if [[ "$selected_path" == "../" ]]; then
      if [[ "$current_path" == "/" ]]; then
        continue
      elif [[ "$current_path" != */* ]]; then
        current_path="/"
      else
        current_path="${current_path:h}"
      fi
      continue
    fi

    if [[ "$current_path" == "/" ]]; then
      current_path="/$selected_path"
    else
      current_path="$current_path/$selected_path"
    fi
  done
}

_sshfs_mounts() {
  emulate -L zsh

  if [[ "$DOTFILES_OS" == "macos" ]]; then
    mount | awk -v root="$SSHFS_MOUNT_ROOT" '
      {
        if (tolower($0) ~ /(sshfs|macfuse|osxfuse)/) {
          line = $0
          sub(/^.* on /, "", line)
          sub(/ \(.*/, "", line)
          if (index(line, root) == 1) {
            print line
          }
        }
      }
    '
  else
    mount | awk -v root="$SSHFS_MOUNT_ROOT" '
      / fuse\.sshfs / {
        if (index($3, root) == 1) {
          print $3
        }
      }
    '
  fi
}

_sshfs_is_mounted() {
  emulate -L zsh

  local mount_path="$1"
  local candidate
  for candidate in "${(@f)$(_sshfs_mounts)}"; do
    if [[ "$candidate" == "$mount_path" ]]; then
      return 0
    fi
  done
  return 1
}

sshm() {
  emulate -L zsh

  local host="${1:-}"
  local remote_path="${2:-}"
  local remote_path_input=""
  local selected_remote_path=""
  local local_path="${3:-}"
  local volume_name=""
  local mount_cmd=()
  local remote_home=""

  if ! command -v sshfs >/dev/null 2>&1; then
    echo "sshfs is not installed"
    return 1
  fi

  if [[ -z "$host" ]]; then
    host="$(_sshfs_select_host)" || return 1
  fi

  if [[ -z "$host" ]]; then
    return 1
  fi

  remote_home="$(ssh "$host" "printf '%s' \"\$HOME\"" 2>/dev/null)"
  [[ -z "$remote_home" ]] && remote_home="/"

  if [[ -z "$remote_path" ]]; then
    selected_remote_path="$(_sshfs_select_remote_path "$host" "$remote_home" "Select remote path")"
    read "remote_path_input?Remote path to mount [$selected_remote_path]: "
    remote_path="${remote_path_input:-$selected_remote_path}"
  fi

  if [[ -z "$local_path" ]]; then
    local_path="$(_sshfs_mount_dir "$host" "$remote_path")"
    read "local_path?Local mount path [$local_path]: "
    local_path="${local_path:-$(_sshfs_mount_dir "$host" "$remote_path")}"
  fi

  if [[ -d "$local_path" ]] && _sshfs_is_mounted "$local_path"; then
    echo "SSHFS mount already exists at ${local_path}"
    builtin cd -- "$local_path"
    return 0
  fi

  mkdir -p "$local_path" 2>/dev/null || true

  volume_name="${local_path:t}"
  mount_cmd=(sshfs "${host}:${remote_path}" "$local_path" -o "${SSHFS_MOUNT_OPTIONS},volname=${volume_name}")
  if [[ ! -w "$local_path" ]]; then
    mount_cmd=(sudo "${mount_cmd[@]}")
  fi

  echo "Mounting ${host}:${remote_path} -> ${local_path}"
  "${mount_cmd[@]}" || return 1
  builtin cd -- "$local_path"
}

sshj() {
  emulate -L zsh

  local mount_path="${1:-}"
  if [[ -z "$mount_path" ]]; then
    if ! command -v fzf >/dev/null 2>&1; then
      echo "fzf is not installed"
      return 1
    fi

    mount_path="$(_sshfs_mounts | fzf \
      --prompt="Jump to SSHFS mount: " \
      --height=40% \
      --reverse \
      --border \
      --header="Mounted SSHFS directories")"
  fi

  [[ -z "$mount_path" ]] && return 1
  builtin cd -- "$mount_path"
}

sshu() {
  emulate -L zsh

  local mount_path="${1:-}"
  local -a mounts
  local unmounted=0
  if [[ -z "$mount_path" ]]; then
    if ! command -v fzf >/dev/null 2>&1; then
      echo "fzf is not installed"
      return 1
    fi

    mounts=("${(@f)$(_sshfs_mounts)}")
    if (( ${#mounts[@]} == 0 )); then
      echo "No SSHFS mounts found under $SSHFS_MOUNT_ROOT"
      return 1
    fi

    mount_path="$(printf '%s\n' "${mounts[@]}" | fzf \
      --prompt="Unmount SSHFS mount: " \
      --height=40% \
      --reverse \
      --border \
      --header="Mounted SSHFS directories")"
  fi

  [[ -z "$mount_path" ]] && return 1

  echo "Unmounting $mount_path"
  if [[ "$DOTFILES_OS" == "macos" ]]; then
    if ! diskutil unmount "$mount_path" >/dev/null 2>&1 &&
      ! umount "$mount_path" >/dev/null 2>&1 &&
      ! sudo diskutil unmount force "$mount_path" >/dev/null 2>&1 &&
      ! sudo umount "$mount_path" >/dev/null 2>&1; then
      if _sshfs_is_mounted "$mount_path"; then
        echo "Unmount failed for $mount_path"
        return 1
      fi
    fi
  else
    if ! fusermount -u "$mount_path" 2>/dev/null &&
      ! umount "$mount_path" 2>/dev/null &&
      ! sudo umount "$mount_path" >/dev/null 2>&1; then
      if _sshfs_is_mounted "$mount_path"; then
        echo "Unmount failed for $mount_path"
        return 1
      fi
    fi
  fi
  unmounted=1

  if (( unmounted == 1 )) && [[ -d "$mount_path" ]]; then
    rmdir "$mount_path" 2>/dev/null || true
  fi
}

sshhome() {
  emulate -L zsh

  mkdir -p "$SSHFS_MOUNT_ROOT"
  builtin cd -- "$SSHFS_MOUNT_ROOT"
}

sshexec() {
  emulate -L zsh

  local host="${1:-}"
  shift 2>/dev/null || true

  if [[ -z "$host" ]]; then
    host="$(_sshfs_select_host)" || return 1
  fi

  [[ -z "$host" ]] && return 1

  if (( $# == 0 )); then
    echo "Usage: sshexec [host] <command...>"
    return 1
  fi

  ssh "$host" "$@"
}

_ssh_x11_locally_available() {
  emulate -L zsh

  if [[ "$DOTFILES_OS" == "macos" ]]; then
    [[ -n "${DISPLAY:-}" ]] || return 1
    [[ -x /usr/X11/bin/xauth ]] || return 1
    pgrep -x XQuartz >/dev/null 2>&1 || return 1
    return 0
  fi

  [[ -n "${DISPLAY:-}" || -n "${WAYLAND_DISPLAY:-}" ]]
}

_ssh_supports_x11_forwarding() {
  emulate -L zsh

  local host="$1"

  _ssh_x11_locally_available || return 1

  ssh \
    -o BatchMode=yes \
    -o ConnectTimeout=5 \
    -o ForwardX11=yes \
    -o ForwardX11Trusted=yes \
    -o ExitOnForwardFailure=yes \
    -o RequestTTY=no \
    "$host" "true" >/dev/null 2>&1
}

sshs() {
  emulate -L zsh

  local host="${1:-}"

  if [[ -z "$host" ]]; then
    host="$(_sshfs_select_host)" || return 1
  fi

  [[ -z "$host" ]] && return 1

  ssh -Y "$host"
}

sshx11check() {
  emulate -L zsh

  local host="${1:-}"
  local script_path="$HOME/dotfiles/scripts/check-remote-x11.sh"

  if [[ -z "$host" ]]; then
    host="$(_sshfs_select_host)" || return 1
  fi

  [[ -z "$host" ]] && return 1

  if [[ ! -f "$script_path" ]]; then
    echo "Script not found: $script_path"
    return 1
  fi

  ssh "$host" 'sh -s' < "$script_path"
}

sshx11() {
  emulate -L zsh

  local host="${1:-}"
  local script_path="$HOME/dotfiles/scripts/setup-remote-x11.sh"
  local remote_tmp=""
  local remote_tmp_quoted=""

  if [[ -z "$host" ]]; then
    host="$(_sshfs_select_host)" || return 1
  fi

  [[ -z "$host" ]] && return 1

  if [[ ! -f "$script_path" ]]; then
    echo "Script not found: $script_path"
    return 1
  fi

  remote_tmp="$(ssh "$host" 'mktemp /tmp/setup-remote-x11.XXXXXX')" || return 1
  remote_tmp_quoted="${(q)remote_tmp}"

  if ! ssh "$host" "cat > $remote_tmp_quoted && chmod 700 $remote_tmp_quoted" < "$script_path"; then
    ssh "$host" "rm -f $remote_tmp_quoted" >/dev/null 2>&1 || true
    return 1
  fi

  ssh -tt "$host" "sh $remote_tmp_quoted; status=\$?; rm -f $remote_tmp_quoted; exit \$status"
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

xqallow() {
  "$HOME/dotfiles/scripts/xquartz-allow-localhost.sh" "$@"
}

if [[ "$DOTFILES_OS" == "macos" && -z "$SSH_CONNECTION" ]]; then
  export DISPLAY=:0
fi
