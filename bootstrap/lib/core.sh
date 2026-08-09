#!/usr/bin/env bash

setup_colors() {
  if [[ -t 1 ]] && [[ -z "${NO_COLOR:-}" ]]; then
    COLOR_RESET="$(printf "\\033[0m")"
    COLOR_BOLD="$(printf "\\033[1m")"
    COLOR_NEXT="$(printf "\\033[1;36m")"
    COLOR_WARN="$(printf "\\033[1;33m")"
    COLOR_INFO="$(printf "\\033[1;34m")"
    COLOR_DONE="$(printf "\\033[1;32m")"
    COLOR_COMMAND="$(printf "\\033[1;7m")"
  fi
}

print_status_header() {
  local level=$1
  local title=$2
  local color=$COLOR_INFO

  case "$level" in
    NEXT) color=$COLOR_NEXT ;;
    WARN) color=$COLOR_WARN ;;
    INFO) color=$COLOR_INFO ;;
    DONE) color=$COLOR_DONE ;;
  esac

  printf "\n%s[%s]%s %s%s%s\n" "$color" "$level" "$COLOR_RESET" "$COLOR_BOLD" "$title" "$COLOR_RESET"
}

print_command_hint() {
  printf "  %s %s%s%s\n" "$1" "$COLOR_COMMAND" "$2" "$COLOR_RESET"
}

print_missing_command_warning() {
  local title=$1 command_name=$2 detail=$3 hint=${4:-}
  print_status_header WARN "${title} missing"
  printf "  Command not found: %s\n  %s\n" "$command_name" "$detail"
  [[ -z "$hint" ]] || print_command_hint "Check:" "$hint"
}

print_warning() {
  print_status_header WARN "$1"
  printf "  %s\n" "$2"
}

ensure_sudo_session() {
  if (( SUDO_SESSION_STARTED == 1 )); then
    return 0
  fi
  if ! need_cmd sudo; then
    print_warning "Administrator access unavailable" "sudo is required for this selected system-level operation."
    return 1
  fi

  print_status_header INFO "Administrator access"
  printf '  Authenticate once; bootstrap will keep this sudo session active only until it exits.\n'
  if ! sudo -v; then
    print_warning "Administrator authentication failed" "The selected system-level operation cannot continue."
    return 1
  fi

  SUDO_SESSION_STARTED=1
  (
    while sudo -n -v >/dev/null 2>&1; do
      sleep "$SUDO_KEEPALIVE_INTERVAL_SECONDS"
    done
  ) &
  SUDO_KEEPALIVE_PID=$!
}

run_sudo() {
  ensure_sudo_session || return 1
  sudo "$@"
}

stop_sudo_session() {
  local session_pid=${SUDO_KEEPALIVE_PID:-}
  if [[ -n "$session_pid" ]]; then
    kill "$session_pid" >/dev/null 2>&1 || true
    wait "$session_pid" 2>/dev/null || true
    SUDO_KEEPALIVE_PID=""
  fi
  if (( ${SUDO_SESSION_STARTED:-0} == 1 )); then
    sudo -k >/dev/null 2>&1 || true
    SUDO_SESSION_STARTED=0
  fi
}

record_install_failure() {
  local title=$1 detail=$2
  INSTALL_FAILURE_MESSAGES[$INSTALL_FAILURE_COUNT]="${title}: ${detail}"
  INSTALL_FAILURE_COUNT=$((INSTALL_FAILURE_COUNT + 1))
}

print_bootstrap_result() {
  local index
  if (( INSTALL_FAILURE_COUNT > 0 )); then
    print_status_header WARN "Bootstrap completed with ${INSTALL_FAILURE_COUNT} issue(s)."
    for ((index = 0; index < INSTALL_FAILURE_COUNT; index++)); do
      printf '  - %s\n' "${INSTALL_FAILURE_MESSAGES[$index]}"
    done
    printf '  Healthy tools were still installed or updated; rerun the failed tool names with --only after fixing the cause.\n'
    return 1
  fi

  if [[ $UPDATE_ONLY -eq 1 ]]; then
    print_status_header DONE "Managed tools update complete."
  else
    print_status_header DONE "Bootstrap complete."
  fi
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1
}

command_runs() {
  local cmd=$1
  shift
  need_cmd "$cmd" && "$cmd" "$@" >/dev/null 2>&1
}

prepend_path_if_dir() {
  local dir=$1 entry
  local -a path_entries=() updated_path=("$dir")

  [[ -d "$dir" ]] || return 0
  IFS=: read -r -a path_entries <<<"${PATH:-}"
  for entry in "${path_entries[@]}"; do
    [[ -z "$entry" || "$entry" == "$dir" ]] || updated_path+=("$entry")
  done
  PATH="$(IFS=:; printf '%s' "${updated_path[*]}")"
  export PATH
}

refresh_command_paths() {
  local brew_bin
  for brew_bin in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
    if [[ -x "$brew_bin" ]]; then
      eval "$("$brew_bin" shellenv 2>/dev/null)"
      break
    fi
  done

  [[ -z "${HOMEBREW_PREFIX:-}" ]] || prepend_path_if_dir "${HOMEBREW_PREFIX}/opt/curl/bin"
  prepend_path_if_dir "${HOME}/.local/bin"
  prepend_path_if_dir "${HOME}/bin"
  prepend_path_if_dir "${HOME}/.npm-global/bin"
  hash -r 2>/dev/null || true
}

need_apt_package() {
  dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -qx 'install ok installed'
}

should_install_cmd() {
  [[ $FORCE_INSTALL -eq 1 ]] || ! need_cmd "$1"
}

should_install_apt_package() {
  [[ $FORCE_INSTALL -eq 1 ]] || ! need_apt_package "$1"
}

should_update_existing() {
  [[ $FORCE_INSTALL -eq 1 ]]
}

need_macos_pkg() {
  pkgutil --pkgs "$1" >/dev/null 2>&1
}

detect_arch() {
  case "$(uname -m)" in
    x86_64|amd64) echo x86_64 ;;
    aarch64|arm64) echo arm64 ;;
    *) echo unsupported ;;
  esac
}

detect_os() {
  if [[ -n "${BOOTSTRAP_OS_OVERRIDE:-}" ]]; then
    if [[ $DRY_RUN -ne 1 ]]; then
      echo "BOOTSTRAP_OS_OVERRIDE is only allowed with --dry-run." >&2
      return 1
    fi
    case "$BOOTSTRAP_OS_OVERRIDE" in
      macos|ubuntu) echo "$BOOTSTRAP_OS_OVERRIDE"; return ;;
      *) echo "Invalid BOOTSTRAP_OS_OVERRIDE: $BOOTSTRAP_OS_OVERRIDE" >&2; return 1 ;;
    esac
  fi

  case "$(uname -s)" in
    Darwin) echo macos ;;
    Linux)
      if [[ -r /etc/os-release ]]; then
        . /etc/os-release
        case "${ID:-}" in
          ubuntu|debian) echo ubuntu ;;
          *) echo unsupported-linux ;;
        esac
      else
        echo unsupported-linux
      fi
      ;;
    *) echo unsupported ;;
  esac
}

run_optional_step() {
  local title=$1
  shift
  if ! "$@"; then
    print_warning "${title} install skipped" "The installer failed; bootstrap will continue so the rest of the dotfiles can still be linked."
    record_install_failure "$title" "installer failed"
  fi
}

usage() {
  cat <<'EOF'
Usage: ./bootstrap.sh [options]

Options:
  --force          Reinstall or update managed tools even if they already exist.
  --update         Update managed tools only; skip relinking and user config.
  --list           List all tools in the manifest and exit.
  --dry-run        Print the selected installation plan without changing the system.
  --only NAMES     Manage only comma-separated tool names; implies --update --force.
  --skip NAMES     Skip comma-separated tool names.
  -h, --help       Show this help message.

For cross-platform plan checks only:
  BOOTSTRAP_OS_OVERRIDE=ubuntu ./bootstrap.sh --dry-run
EOF
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --force) FORCE_INSTALL=1 ;;
      --update) UPDATE_ONLY=1; FORCE_INSTALL=1 ;;
      --list) LIST_TOOLS=1 ;;
      --dry-run) DRY_RUN=1 ;;
      --only)
        [[ $# -ge 2 ]] || { echo "--only requires a comma-separated value." >&2; exit 1; }
        ONLY_TOOLS=$2
        UPDATE_ONLY=1
        FORCE_INSTALL=1
        shift
        ;;
      --only=*)
        ONLY_TOOLS=${1#*=}
        UPDATE_ONLY=1
        FORCE_INSTALL=1
        ;;
      --skip)
        [[ $# -ge 2 ]] || { echo "--skip requires a comma-separated value." >&2; exit 1; }
        SKIP_TOOLS=$2
        shift
        ;;
      --skip=*) SKIP_TOOLS=${1#*=} ;;
      -h|--help) usage; exit 0 ;;
      *) echo "Unknown option: $1" >&2; usage >&2; exit 1 ;;
    esac
    shift
  done
}
