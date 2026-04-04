#!/bin/sh
set -eu

info() {
  printf '[INFO] %s\n' "$*"
}

warn() {
  printf '[WARN] %s\n' "$*"
}

done_msg() {
  printf '[DONE] %s\n' "$*"
}

has_cmd() {
  command -v "$1" >/dev/null 2>&1
}

run_root() {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
    return
  fi

  if has_cmd sudo; then
    sudo "$@"
    return
  fi

  warn "need root privileges for: $*"
  exit 1
}

detect_pkg_manager() {
  for candidate in apt-get dnf yum zypper apk; do
    if has_cmd "$candidate"; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  return 1
}

install_xauth() {
  if has_cmd xauth; then
    done_msg "xauth already installed at $(command -v xauth)"
    return 0
  fi

  pkg_manager=$(detect_pkg_manager || true)
  case "$pkg_manager" in
    apt-get)
      info "installing xauth via apt-get"
      run_root apt-get update
      run_root apt-get install -y xauth x11-apps
      ;;
    dnf)
      info "installing xauth via dnf"
      run_root dnf install -y xauth xorg-x11-apps
      ;;
    yum)
      info "installing xauth via yum"
      run_root yum install -y xauth xorg-x11-apps
      ;;
    zypper)
      info "installing xauth via zypper"
      run_root zypper --non-interactive install xauth xeyes
      ;;
    apk)
      info "installing xauth via apk"
      run_root apk add xauth xclock
      ;;
    *)
      warn "unsupported package manager; install xauth manually"
      return 1
      ;;
  esac

  if has_cmd xauth; then
    done_msg "xauth installed at $(command -v xauth)"
  else
    warn "xauth install command completed but xauth is still unavailable"
    return 1
  fi
}

detect_sshd_config() {
  for candidate in /etc/ssh/sshd_config /etc/sshd_config; do
    if [ -f "$candidate" ]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  return 1
}

ensure_user_xauthority_bridge() {
  user_home="${HOME:-}"
  xauthority_file="${user_home}/.Xauthority"
  codex_home="${user_home}/.codex-home"
  codex_xauthority="${codex_home}/.Xauthority"

  if [ -z "$user_home" ] || [ ! -d "$user_home" ]; then
    warn "could not determine user home; skipping .Xauthority bridge setup"
    return 1
  fi

  if [ ! -f "$xauthority_file" ]; then
    warn "missing $xauthority_file; skipping .codex-home/.Xauthority bridge for now"
    return 1
  fi

  mkdir -p "$codex_home"
  ln -sfn "$xauthority_file" "$codex_xauthority"
  done_msg "ensured $codex_xauthority -> $xauthority_file"
}

ensure_sshd_option() {
  key="$1"
  value="$2"
  file="$3"
  tmp_file=$(mktemp)

  awk -v key="$key" -v value="$value" '
    BEGIN { done = 0 }
    {
      lower = tolower($1)
      target = tolower(key)
      if ($0 ~ /^[[:space:]]*#/) {
        print
        next
      }
      if (lower == target) {
        if (done == 0) {
          printf "%s %s\n", key, value
          done = 1
        }
        next
      }
      print
    }
    END {
      if (done == 0) {
        printf "%s %s\n", key, value
      }
    }
  ' "$file" >"$tmp_file"

  run_root cp "$tmp_file" "$file"
  rm -f "$tmp_file"
}

restart_ssh_service() {
  if has_cmd systemctl; then
    for candidate in sshd ssh; do
      if systemctl status "$candidate" >/dev/null 2>&1; then
        info "restarting $candidate via systemctl"
        run_root systemctl restart "$candidate"
        done_msg "restarted $candidate"
        return 0
      fi
    done
  fi

  if has_cmd service; then
    for candidate in sshd ssh; do
      if service "$candidate" status >/dev/null 2>&1; then
        info "restarting $candidate via service"
        run_root service "$candidate" restart
        done_msg "restarted $candidate"
        return 0
      fi
    done
  fi

  warn "could not determine SSH service manager; restart sshd manually"
  return 1
}

main() {
  info "host=$(hostname 2>/dev/null || uname -n)"

  install_xauth

  sshd_config_file=$(detect_sshd_config || true)
  if [ -z "$sshd_config_file" ]; then
    warn "sshd_config not found in /etc/ssh/sshd_config or /etc/sshd_config"
    exit 1
  fi

  info "updating $sshd_config_file"
  ensure_sshd_option X11Forwarding yes "$sshd_config_file"
  ensure_sshd_option X11UseLocalhost yes "$sshd_config_file"
  done_msg "ensured X11Forwarding yes"
  done_msg "ensured X11UseLocalhost yes"

  ensure_user_xauthority_bridge || true
  restart_ssh_service

  printf '\n'
  done_msg "remote X11 setup finished"
  info "test with: ssh -Y <host>"
}

main "$@"
