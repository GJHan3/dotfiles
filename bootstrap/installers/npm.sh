#!/usr/bin/env bash

ensure_npm_user_prefix() {
  local npm_registry
  need_cmd npm || return 0

  mkdir -p "${HOME}/.npm-global" || return 1
  npm config set prefix "${HOME}/.npm-global" --location=user 2>/dev/null || true
  export NPM_CONFIG_PREFIX="${HOME}/.npm-global"

  npm_registry="$(npm config get registry 2>/dev/null || true)"
  if [[ -z "$npm_registry" || "$npm_registry" == undefined || "$npm_registry" == "$NPM_OFFICIAL_REGISTRY/" || "$npm_registry" == "$NPM_OFFICIAL_REGISTRY" ]]; then
    npm config set registry "$NPM_MIRROR_REGISTRY" 2>/dev/null || true
  fi
  prepend_path_if_dir "${HOME}/.npm-global/bin"
}

check_node_runtime() {
  local node_version node_major
  if ! need_cmd node; then
    print_warning "Node.js missing" "npm-based CLI installs require Node.js ${NODE_MIN_MAJOR}+."
    return 1
  fi

  node_version="$(node -v 2>/dev/null || true)"
  node_major=${node_version#v}
  node_major=${node_major%%.*}
  if [[ ! "$node_major" =~ ^[0-9]+$ ]] || (( node_major < NODE_MIN_MAJOR )); then
    print_warning "Node.js version is below bootstrap minimum" "Detected ${node_version:-unknown}; current npm tooling requires Node.js ${NODE_MIN_MAJOR}.x or newer."
    return 1
  fi
}

run_npm_global_install() {
  local package=$1 registry=$2 package_name
  case "$package" in
    @*/*@*) package_name=${package%@*} ;;
    @*/*) package_name=$package ;;
    *@*) package_name=${package%@*} ;;
    *) package_name=$package ;;
  esac

  # npm 12 blocks dependency lifecycle scripts unless each package is allowed.
  # Restrict permission to the manifest package being installed instead of
  # enabling arbitrary global install scripts in user configuration.
  npm i -g "$package" \
    --include=optional \
    --omit=dev \
    --allow-scripts="$package_name" \
    --registry="$registry"
}

install_npm_global_package() {
  local package=$1 label=$2 command=$3 health=${4:-} registry installed_cmd
  local -a health_args=()

  ensure_npm_user_prefix || return 1
  refresh_command_paths || return 1
  if ! need_cmd npm; then
    echo "Skipping ${label} install: npm is not available." >&2
    return 1
  fi
  check_node_runtime || return 1
  [[ -z "$health" ]] || read -r -a health_args <<<"$health"

  for registry in "$NPM_OFFICIAL_REGISTRY" "$NPM_MIRROR_REGISTRY"; do
    if run_npm_global_install "$package" "$registry"; then
      refresh_command_paths
      installed_cmd="${HOME}/.npm-global/bin/${command}"
      if [[ -x "$installed_cmd" ]] && "$installed_cmd" "${health_args[@]}" >/dev/null 2>&1; then
        return 0
      fi
      print_warning "${label} health check failed" "npm install succeeded from ${registry}, but ${installed_cmd} still does not run. Trying the next registry."
    fi
  done

  echo "Failed to install ${label} with npm." >&2
  return 1
}

command_runs_health() {
  local command=$1 health=$2
  local -a health_args=()
  [[ -z "$health" ]] || read -r -a health_args <<<"$health"
  need_cmd "$command" && "$command" "${health_args[@]}" >/dev/null 2>&1
}

install_npm_manifest_row() {
  local name=$1 kind=$2 package=$3 command=$4 health=$5 platform=$6 label=$7 fallback=$8
  [[ "$kind" == npm ]] || return 0
  tool_selected "$name" || return 0
  platform_matches "$platform" || return 0

  if [[ "$name" != npm ]] && command_runs_health "$command" "$health"; then
    [[ $FORCE_INSTALL -eq 0 ]] && return 0
  elif [[ "$name" != npm ]] && need_cmd "$command"; then
    print_warning "${label} needs reinstall" "The command exists but failed its health check, so bootstrap will reinstall ${package} under ~/.npm-global."
  fi

  if install_npm_global_package "$package" "$label" "$command" "$health"; then
    return 0
  fi
  if [[ -n "$fallback" ]]; then
    print_warning "${label} fallback" "The primary package did not pass its health check, so bootstrap will try ${fallback}."
    if install_npm_global_package "$fallback" "$label" "$command" "$health"; then
      return 0
    fi
  fi
  echo "Continuing without ${label}." >&2
  record_install_failure "$name" "npm package installation or health check failed"
  return 0
}

install_manifest_npm_tools() {
  for_each_manifest_tool install_npm_manifest_row
}

install_lark_skills() {
  tool_selected lark-skills || return 0
  if ! need_cmd npx; then
    echo "Skipping Lark skills install: npx is not available." >&2
    record_install_failure lark-skills "npx is not available"
    return 0
  fi
  if ! npx -y skills add larksuite/cli -g -y; then
    echo "Skipping Lark skills install: npx skills add failed." >&2
    record_install_failure lark-skills "npx skills add failed"
  fi
}
