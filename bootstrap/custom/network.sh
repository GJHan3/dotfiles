#!/usr/bin/env bash

ensure_tailscale_apt_repository() {
  local distro_id distro_codename
  tool_selected tailscale || return 1
  if [[ $FORCE_INSTALL -eq 0 ]] && [[ -f "$TAILSCALE_SOURCE_FILE" ]] && [[ -f "$TAILSCALE_KEYRING" ]]; then
    return 0
  fi
  if [[ ! -r /etc/os-release ]]; then
    print_warning "Tailscale setup skipped" "Could not read /etc/os-release."
    return 1
  fi
  . /etc/os-release
  distro_id=${ID:-}
  distro_codename=${VERSION_CODENAME:-}
  if [[ "$distro_id" != ubuntu && "$distro_id" != debian ]] || [[ -z "$distro_codename" ]]; then
    print_warning "Tailscale setup skipped" "Could not select a supported Ubuntu/Debian repository."
    return 1
  fi
  sudo mkdir -p "$(dirname "$TAILSCALE_KEYRING")" "$(dirname "$TAILSCALE_SOURCE_FILE")" || return 1
  curl -fsSL "${TAILSCALE_STABLE_URL}/${distro_id}/${distro_codename}.noarmor.gpg" | sudo tee "$TAILSCALE_KEYRING" >/dev/null || return 1
  sudo chmod 0644 "$TAILSCALE_KEYRING" || return 1
  curl -fsSL "${TAILSCALE_STABLE_URL}/${distro_id}/${distro_codename}.tailscale-keyring.list" | sudo tee "$TAILSCALE_SOURCE_FILE" >/dev/null || return 1
}

install_tailscale_macos() {
  local pkg_href pkg_url pkg_name latest_version installed_version tmp_pkg
  tool_selected tailscale || return 0
  pkg_href="$(curl -fsSL "${TAILSCALE_STABLE_URL}/" | sed -n 's/.*href="\([^"]*Tailscale-[^"]*-macos\.pkg\)".*/\1/p' | head -n 1)" || return 1
  [[ -n "$pkg_href" ]] || { echo "Failed to detect latest Tailscale macOS package." >&2; return 1; }
  case "$pkg_href" in
    http*) pkg_url=$pkg_href ;;
    *) pkg_url="${TAILSCALE_STABLE_URL}/${pkg_href}" ;;
  esac
  pkg_name=${pkg_url##*/}
  latest_version="$(printf '%s' "$pkg_name" | sed -n 's/^Tailscale-\([0-9][0-9.]*\)-macos\.pkg$/\1/p')"
  installed_version="$(defaults read /Applications/Tailscale.app/Contents/Info.plist CFBundleShortVersionString 2>/dev/null || true)"
  if [[ $FORCE_INSTALL -eq 0 && -n "$latest_version" && "$installed_version" == "$latest_version" ]]; then
    return 0
  fi
  tmp_pkg="/tmp/${pkg_name}"
  curl -fL "$pkg_url" -o "$tmp_pkg" || return 1
  sudo installer -pkg "$tmp_pkg" -target / || return 1
}
