#!/usr/bin/env bash

resolve_node_target_major() {
  local latest_major
  if [[ "$NODE_TARGET_MAJOR" =~ ^[0-9]+$ ]]; then
    return 0
  fi

  latest_major="$(
    curl -fsSL "$NODE_RELEASE_INDEX" 2>/dev/null |
      sed -n 's/^[[:space:]]*{"version":"v\([0-9][0-9]*\)\..*/\1/p' |
      head -n 1 || true
  )"
  if [[ "$latest_major" =~ ^[0-9]+$ ]] && (( latest_major >= NODE_MIN_MAJOR )); then
    NODE_TARGET_MAJOR=$latest_major
    return 0
  fi

  NODE_TARGET_MAJOR=$NODE_MIN_MAJOR
  print_warning "Latest Node.js detection failed" "Could not resolve the current release from nodejs.org; falling back to Node.js ${NODE_MIN_MAJOR}.x."
  record_install_failure node "could not resolve the latest Node.js major"
}

install_nodesource_ubuntu() {
  local arch key_url source_url
  resolve_node_target_major
  if [[ $FORCE_INSTALL -eq 0 ]] && [[ -f "$NODESOURCE_SOURCE_FILE" ]] && [[ -f "$NODESOURCE_KEYRING" ]] && grep -q "node_${NODE_TARGET_MAJOR}\.x" "$NODESOURCE_SOURCE_FILE"; then
    return 0
  fi

  arch="$(dpkg --print-architecture)"
  key_url="https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key"
  source_url="https://deb.nodesource.com/node_${NODE_TARGET_MAJOR}.x"
  ensure_sudo_session || return 1
  sudo apt-get update || return 1
  sudo apt-get install -y ca-certificates curl gnupg || return 1
  sudo mkdir -p "$(dirname "$NODESOURCE_KEYRING")" "$(dirname "$NODESOURCE_SOURCE_FILE")" || return 1
  curl -fsSL "$key_url" | sudo gpg --dearmor --yes -o "$NODESOURCE_KEYRING" || return 1
  sudo chmod 0644 "$NODESOURCE_KEYRING" || return 1
  printf 'Types: deb\nURIs: %s\nSuites: nodistro\nComponents: main\nArchitectures: %s\nSigned-By: %s\n' \
    "$source_url" "$arch" "$NODESOURCE_KEYRING" | sudo tee "$NODESOURCE_SOURCE_FILE" >/dev/null || return 1
  sudo apt-get update || return 1
  sudo apt-get remove -y npm libnode-dev 2>/dev/null || true
  sudo apt-get install -y nodejs || return 1
}

ensure_nodesource_ubuntu() {
  tool_selected node || return 0
  if ! install_nodesource_ubuntu; then
    print_warning "NodeSource setup failed" "Falling back to the distro nodejs package for this run."
    record_install_failure node "NodeSource setup failed; distro fallback may not be the latest release"
  fi
}
