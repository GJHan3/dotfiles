#!/usr/bin/env bash

collect_apt_manifest_row() {
  local name=$1 kind=$2 package=$3 command=$4 health=$5 platform=$6 label=$7 fallback=$8
  [[ "$kind" == apt ]] || return 0
  tool_selected "$name" || return 0
  platform_matches "$platform" || return 0
  should_install_apt_package "$package" && APT_PACKAGES+=("$package")
}

run_ubuntu_release_installers() {
  tool_selected neovim && run_optional_step Neovim install_neovim_ubuntu
  tool_selected lazygit && run_optional_step LazyGit install_lazygit_ubuntu
  tool_selected stylua && run_optional_step StyLua install_stylua_ubuntu
  tool_selected yazi && run_optional_step Yazi install_yazi_ubuntu
  return 0
}

install_packages_ubuntu() {
  local can_install_tailscale=0 package
  local -a APT_PACKAGES=()

  if tool_selected lazygit && [[ -f /etc/apt/sources.list.d/lazygit-team-ubuntu-release-jammy.list ]]; then
    run_sudo rm -f /etc/apt/sources.list.d/lazygit-team-ubuntu-release-jammy.list
  fi
  ensure_nodesource_ubuntu
  if tool_selected node && should_install_apt_package nodejs; then
    APT_PACKAGES+=(nodejs)
  fi
  if tool_selected tailscale; then
    if ensure_tailscale_apt_repository; then
      can_install_tailscale=1
    else
      record_install_failure tailscale "official apt repository setup failed"
    fi
  fi
  for_each_manifest_tool collect_apt_manifest_row
  if (( can_install_tailscale == 1 )) && should_install_apt_package tailscale; then
    APT_PACKAGES+=(tailscale)
  fi

  if (( ${#APT_PACKAGES[@]} > 0 )); then
    if ! run_sudo apt-get update; then
      print_warning "APT update failed" "Continuing with existing package metadata; latest versions cannot be guaranteed."
      record_install_failure apt "package metadata update failed"
    fi
    for package in "${APT_PACKAGES[@]}"; do
      if ! run_sudo apt-get install -y "$package"; then
        print_warning "APT package install failed" "Continuing after ${package} failed."
        record_install_failure "$package" "apt install failed"
      fi
    done
  fi
  if tool_selected tailscale && need_cmd systemctl && need_cmd tailscale; then
    if ! systemctl is-enabled --quiet tailscaled 2>/dev/null || ! systemctl is-active --quiet tailscaled 2>/dev/null; then
      run_sudo systemctl enable --now tailscaled 2>/dev/null || true
    fi
  fi
  refresh_command_paths
  if tool_selected fd && ! need_cmd fd && [[ -x /usr/bin/fdfind ]]; then
    mkdir -p "${HOME}/.local/bin" || return 1
    ln -sfn /usr/bin/fdfind "${HOME}/.local/bin/fd" || return 1
  fi
  run_ubuntu_release_installers
}
