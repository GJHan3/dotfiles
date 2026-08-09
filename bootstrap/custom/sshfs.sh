#!/usr/bin/env bash

install_latest_sshfs_macos() {
  local build_cmd version current_version release_json pkg_url source_url archive_path source_dir build_dir install_prefix
  release_json="$(curl -fsSL "$SSHFS_RELEASE_API")" || return 1
  version="$(printf '%s' "$release_json" | sed -n 's/.*"tag_name":[[:space:]]*"sshfs-\([^"]*\)".*/\1/p' | head -n 1)"
  [[ "$version" =~ ^[0-9]+(\.[0-9]+)*$ ]] || { echo "Failed to detect a safe latest SSHFS version." >&2; return 1; }

  current_version=""
  if need_cmd sshfs; then
    if [[ -r "$SSHFS_VERSION_FILE" ]]; then
      current_version="$(sed -n '1p' "$SSHFS_VERSION_FILE")"
    elif need_macos_pkg io.macfuse.installer.components.sshfs; then
      current_version="$(pkgutil --pkg-info io.macfuse.installer.components.sshfs 2>/dev/null | sed -n 's/^version: //p')"
    fi
  fi
  if [[ $FORCE_INSTALL -eq 0 && "$current_version" == "$version" ]]; then
    return 0
  fi

  pkg_url="https://github.com/libfuse/sshfs/releases/download/sshfs-${version}/sshfs-${version}.pkg"
  if curl -fsIL "$pkg_url" >/dev/null 2>&1; then
    archive_path="/tmp/sshfs-${version}.pkg"
    curl -fL "$pkg_url" -o "$archive_path" || return 1
    run_sudo /usr/sbin/installer -pkg "$archive_path" -target / || return 1
    mkdir -p "$(dirname "$SSHFS_VERSION_FILE")" || return 1
    printf '%s\n' "$version" > "$SSHFS_VERSION_FILE" || return 1
    return 0
  fi

  for build_cmd in meson ninja pkg-config; do
    need_cmd "$build_cmd" || { echo "Cannot build SSHFS ${version}: ${build_cmd} is missing." >&2; return 1; }
  done
  if ! PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:${PKG_CONFIG_PATH:-}" pkg-config --exists 'fuse3 >= 3.1.0' glib-2.0 gthread-2.0; then
    echo "Cannot build SSHFS ${version}: macFUSE or GLib development metadata is missing." >&2
    return 1
  fi

  source_url="https://github.com/libfuse/sshfs/releases/download/sshfs-${version}/sshfs-${version}.tar.xz"
  archive_path="/tmp/sshfs-${version}.tar.xz"
  source_dir="/tmp/sshfs-${version}-source"
  build_dir="/tmp/sshfs-${version}-build"
  install_prefix="${HOME}/.local"
  curl -fL "$source_url" -o "$archive_path" || return 1
  rm -rf "$source_dir" "$build_dir" || return 1
  mkdir -p "$source_dir" || return 1
  tar -C "$source_dir" --strip-components=1 -xJf "$archive_path" || return 1
  export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:${PKG_CONFIG_PATH:-}"
  meson setup "$build_dir" "$source_dir" --prefix="$install_prefix" --buildtype=release || return 1
  meson compile -C "$build_dir" || return 1
  mkdir -p "${install_prefix}/bin" || return 1
  install -m 0755 "${build_dir}/sshfs" "${install_prefix}/bin/sshfs" || return 1
  mkdir -p "$(dirname "$SSHFS_VERSION_FILE")" || return 1
  printf '%s\n' "$version" > "$SSHFS_VERSION_FILE" || return 1
}

install_sshfs_macos() {
  local brew_bin=$1 macfuse_dmg mount_point macfuse_failed=0
  tool_selected sshfs || return 0
  if ! "$brew_bin" list --cask "$MACFUSE_CASK" >/dev/null 2>&1; then
    if ensure_sudo_session; then
      "$brew_bin" install --cask "$MACFUSE_CASK" || macfuse_failed=1
    else
      macfuse_failed=1
    fi
  elif ! need_macos_pkg io.macfuse.installer.components.core; then
    if ensure_sudo_session; then
      "$brew_bin" reinstall --cask "$MACFUSE_CASK" || macfuse_failed=1
    else
      macfuse_failed=1
    fi
  elif [[ -n "$("$brew_bin" outdated --cask --greedy --quiet "$MACFUSE_CASK" 2>/dev/null)" ]]; then
    if ensure_sudo_session; then
      "$brew_bin" upgrade --cask --greedy "$MACFUSE_CASK" || macfuse_failed=1
    else
      macfuse_failed=1
    fi
  fi
  if (( macfuse_failed == 1 )); then
    print_warning "macFUSE update failed" "Continuing with the installed macFUSE libraries so SSHFS can still be updated under ~/.local."
  fi
  install_latest_sshfs_macos || return 1

  macfuse_dmg="$("$brew_bin" --cache --cask "$MACFUSE_CASK" 2>/dev/null || true)"
  if [[ -n "$macfuse_dmg" ]]; then
    mount_point="$(hdiutil info | awk -v dmg="$macfuse_dmg" '$0 ~ dmg {found=1} found && /\/Volumes\// {print $1; exit}')"
    [[ -z "$mount_point" ]] || hdiutil detach "$mount_point" >/dev/null 2>&1 || true
  fi
  return "$macfuse_failed"
}
