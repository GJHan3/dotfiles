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
  ensure_sudo_session || return 1
  sudo mkdir -p "$(dirname "$TAILSCALE_KEYRING")" "$(dirname "$TAILSCALE_SOURCE_FILE")" || return 1
  curl -fsSL "${TAILSCALE_STABLE_URL}/${distro_id}/${distro_codename}.noarmor.gpg" | sudo tee "$TAILSCALE_KEYRING" >/dev/null || return 1
  sudo chmod 0644 "$TAILSCALE_KEYRING" || return 1
  curl -fsSL "${TAILSCALE_STABLE_URL}/${distro_id}/${distro_codename}.tailscale-keyring.list" | sudo tee "$TAILSCALE_SOURCE_FILE" >/dev/null || return 1
}

installed_tailscale_macos_version() {
  local app_plist=/Applications/Tailscale.app/Contents/Info.plist installed_version

  installed_version=""
  if [[ -r "$app_plist" ]] && need_cmd plutil; then
    installed_version="$(plutil -extract CFBundleShortVersionString raw -o - "$app_plist" 2>/dev/null || true)"
  fi
  if [[ ! "$installed_version" =~ ^[0-9]+(\.[0-9]+)*$ ]] && need_cmd pkgutil; then
    installed_version="$(pkgutil --pkg-info com.tailscale.ipn.macsys 2>/dev/null | sed -n 's/^version: //p')"
  fi
  [[ "$installed_version" =~ ^[0-9]+(\.[0-9]+)*$ ]] || return 1
  printf '%s\n' "$installed_version"
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
  [[ "$latest_version" =~ ^[0-9]+(\.[0-9]+)*$ ]] || { echo "Failed to parse the latest Tailscale macOS version." >&2; return 1; }
  installed_version="$(installed_tailscale_macos_version || true)"
  if [[ "$installed_version" == "$latest_version" ]]; then
    return 0
  fi
  tmp_pkg="/tmp/${pkg_name}"
  curl -fL "$pkg_url" -o "$tmp_pkg" || return 1
  run_sudo installer -pkg "$tmp_pkg" -target / || return 1
  installed_version="$(installed_tailscale_macos_version || true)"
  if [[ "$installed_version" != "$latest_version" ]]; then
    echo "Tailscale installer completed, but version ${latest_version} was not detected afterward." >&2
    return 1
  fi
}
