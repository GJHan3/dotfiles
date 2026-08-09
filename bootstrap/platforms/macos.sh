#!/usr/bin/env bash

install_homebrew() {
  need_cmd brew && return 0
  local installer
  installer="$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || return 1
  /bin/bash -c "$installer"
}

collect_brew_manifest_row() {
  local name=$1 kind=$2 package=$3 command=$4 health=$5 platform=$6 label=$7 fallback=$8
  [[ "$kind" == brew ]] || return 0
  tool_selected "$name" || return 0
  platform_matches "$platform" || return 0

  if ! "$BREW_BIN" list --formula "$package" >/dev/null 2>&1; then
    BREW_FORMULAE+=("$package")
  elif [[ $FORCE_INSTALL -eq 1 || "$name" == node ]] && [[ -n "$("$BREW_BIN" outdated --formula --quiet "$package" 2>/dev/null)" ]]; then
    BREW_UPGRADES+=("$package")
  fi
}

install_im_select_macos() {
  local brew_bin=$1
  tool_selected im-select || return 0
  "$brew_bin" tap daipeihust/tap || return 1
  if "$brew_bin" help trust >/dev/null 2>&1; then
    # Homebrew 5+ requires explicit trust for third-party tap content. Limit
    # trust to the single formula managed here instead of trusting the tap.
    "$brew_bin" trust --formula daipeihust/tap/im-select || return 1
  fi
  if ! "$brew_bin" list --formula im-select >/dev/null 2>&1; then
    "$brew_bin" install im-select || return 1
  elif [[ $FORCE_INSTALL -eq 1 ]]; then
    if [[ -n "$("$brew_bin" outdated --formula --quiet im-select 2>/dev/null)" ]]; then
      "$brew_bin" upgrade im-select || return 1
    else
      "$brew_bin" reinstall im-select || return 1
    fi
  fi
  refresh_command_paths || return 1
}

install_packages_macos() {
  local formula
  local -a BREW_FORMULAE=() BREW_UPGRADES=()
  local BREW_BIN
  if ! install_homebrew; then
    print_warning "Homebrew install failed" "Managed macOS packages could not be installed."
    record_install_failure homebrew "installation failed"
    return 0
  fi
  refresh_command_paths
  if [[ -x /opt/homebrew/bin/brew ]]; then
    BREW_BIN=/opt/homebrew/bin/brew
  elif [[ -x /usr/local/bin/brew ]]; then
    BREW_BIN=/usr/local/bin/brew
  else
    BREW_BIN="$(command -v brew)"
  fi

  if [[ $FORCE_INSTALL -eq 1 ]]; then
    if ! "$BREW_BIN" update; then
      print_warning "Homebrew update failed" "Continuing with the existing package metadata."
      record_install_failure homebrew "package metadata update failed; latest versions cannot be guaranteed"
    fi
  fi
  for_each_manifest_tool collect_brew_manifest_row
  if (( ${#BREW_FORMULAE[@]} > 0 )); then
    for formula in "${BREW_FORMULAE[@]}"; do
      if ! "$BREW_BIN" install "$formula"; then
        print_warning "Homebrew formula install failed" "Continuing after ${formula} failed."
        record_install_failure "$formula" "Homebrew install failed"
      fi
    done
  fi
  if (( ${#BREW_UPGRADES[@]} > 0 )); then
    for formula in "${BREW_UPGRADES[@]}"; do
      if ! "$BREW_BIN" upgrade "$formula"; then
        print_warning "Homebrew formula upgrade failed" "Continuing after ${formula} failed."
        record_install_failure "$formula" "Homebrew upgrade failed"
      fi
    done
  fi
  refresh_command_paths
  run_optional_step im-select install_im_select_macos "$BREW_BIN"
  run_optional_step SSHFS install_sshfs_macos "$BREW_BIN"
  run_optional_step Tailscale install_tailscale_macos
}
