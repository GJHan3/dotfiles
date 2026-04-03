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

sshd_config_file=""
for candidate in /etc/ssh/sshd_config /etc/sshd_config; do
  if [ -f "$candidate" ]; then
    sshd_config_file="$candidate"
    break
  fi
done

info "host=$(hostname 2>/dev/null || uname -n)"
info "kernel=$(uname -s 2>/dev/null || printf unknown)"

if has_cmd xauth; then
  xauth_path=$(command -v xauth)
  done_msg "xauth found at $xauth_path"
else
  warn "xauth not found; X11 forwarding usually needs it"
fi

if [ -n "$sshd_config_file" ]; then
  info "checking $sshd_config_file"
  x11_forwarding_state=$(
    awk '
      BEGIN { value = "unset" }
      /^[[:space:]]*#/ { next }
      tolower($1) == "x11forwarding" { value = tolower($2) }
      END { print value }
    ' "$sshd_config_file"
  )
  x11_localhost_state=$(
    awk '
      BEGIN { value = "unset" }
      /^[[:space:]]*#/ { next }
      tolower($1) == "x11uselocalhost" { value = tolower($2) }
      END { print value }
    ' "$sshd_config_file"
  )

  if [ "$x11_forwarding_state" = "yes" ]; then
    done_msg "X11Forwarding yes"
  elif [ "$x11_forwarding_state" = "no" ]; then
    warn "X11Forwarding no"
  else
    warn "X11Forwarding not explicitly set"
  fi

  if [ "$x11_localhost_state" = "yes" ]; then
    done_msg "X11UseLocalhost yes"
  elif [ "$x11_localhost_state" = "no" ]; then
    warn "X11UseLocalhost no"
  else
    warn "X11UseLocalhost not explicitly set"
  fi
else
  warn "sshd_config not found in /etc/ssh/sshd_config or /etc/sshd_config"
fi

if has_cmd systemctl; then
  service_name=""
  for candidate in sshd ssh; do
    if systemctl status "$candidate" >/dev/null 2>&1; then
      service_name="$candidate"
      break
    fi
  done

  if [ -n "$service_name" ]; then
    if systemctl is-active "$service_name" >/dev/null 2>&1; then
      done_msg "service $service_name is active"
    else
      warn "service $service_name is not active"
    fi
  else
    warn "could not identify ssh service name via systemctl"
  fi
elif has_cmd service; then
  warn "systemctl not available; check ssh service state with service ssh status or service sshd status"
else
  warn "no service manager probe available"
fi

printf '\n'
info "recommended remote settings:"
printf '  X11Forwarding yes\n'
printf '  X11UseLocalhost yes\n'
info "after editing sshd_config, restart sshd or ssh"
