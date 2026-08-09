#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP_DIR="${DOTFILES_DIR}/bootstrap"
TOOLS_MANIFEST="${BOOTSTRAP_DIR}/tools.tsv"
DEPENDENCY_MANIFEST="${BOOTSTRAP_DIR}/dependencies.tsv"

OH_MY_ZSH_DIR="${HOME}/.oh-my-zsh"
P10K_DIR="${OH_MY_ZSH_DIR}/custom/themes/powerlevel10k"
ZSH_CUSTOM_DIR="${OH_MY_ZSH_DIR}/custom"
ZSH_AUTOSUGGESTIONS_DIR="${ZSH_CUSTOM_DIR}/plugins/zsh-autosuggestions"
ZSH_SYNTAX_HIGHLIGHTING_DIR="${ZSH_CUSTOM_DIR}/plugins/zsh-syntax-highlighting"

INTERACTIVE=0
FORCE_INSTALL=0
UPDATE_ONLY=0
LIST_TOOLS=0
DRY_RUN=0
ONLY_TOOLS=""
SKIP_TOOLS=""
CURRENT_OS=""
INSTALL_FAILURE_COUNT=0
INSTALL_FAILURE_MESSAGES=()

NPM_MIRROR_REGISTRY="https://registry.npmmirror.com"
NPM_OFFICIAL_REGISTRY="https://registry.npmjs.org"
NODE_MIN_MAJOR=26
NODE_TARGET_MAJOR=""
NODE_RELEASE_INDEX="https://nodejs.org/dist/index.json"
NODESOURCE_KEYRING="/usr/share/keyrings/nodesource.gpg"
NODESOURCE_SOURCE_FILE="/etc/apt/sources.list.d/nodesource.sources"
TAILSCALE_STABLE_URL="https://pkgs.tailscale.com/stable"
TAILSCALE_KEYRING="/usr/share/keyrings/tailscale-archive-keyring.gpg"
TAILSCALE_SOURCE_FILE="/etc/apt/sources.list.d/tailscale.list"
MACFUSE_CASK=macfuse
SSHFS_RELEASE_API="https://api.github.com/repos/libfuse/sshfs/releases/latest"
SSHFS_VERSION_FILE="${HOME}/.local/state/dotfiles-bootstrap/sshfs.version"

COLOR_RESET=""
COLOR_BOLD=""
COLOR_NEXT=""
COLOR_WARN=""
COLOR_INFO=""
COLOR_DONE=""
COLOR_COMMAND=""

[[ ! -t 0 || ! -t 1 ]] || INTERACTIVE=1

# shellcheck source=bootstrap/lib/core.sh
. "${BOOTSTRAP_DIR}/lib/core.sh"
# shellcheck source=bootstrap/lib/manifest.sh
. "${BOOTSTRAP_DIR}/lib/manifest.sh"
# shellcheck source=bootstrap/installers/npm.sh
. "${BOOTSTRAP_DIR}/installers/npm.sh"
# shellcheck source=bootstrap/custom/node.sh
. "${BOOTSTRAP_DIR}/custom/node.sh"
# shellcheck source=bootstrap/custom/github-releases.sh
. "${BOOTSTRAP_DIR}/custom/github-releases.sh"
# shellcheck source=bootstrap/custom/network.sh
. "${BOOTSTRAP_DIR}/custom/network.sh"
# shellcheck source=bootstrap/custom/sshfs.sh
. "${BOOTSTRAP_DIR}/custom/sshfs.sh"
# shellcheck source=bootstrap/platforms/macos.sh
. "${BOOTSTRAP_DIR}/platforms/macos.sh"
# shellcheck source=bootstrap/platforms/ubuntu.sh
. "${BOOTSTRAP_DIR}/platforms/ubuntu.sh"
# shellcheck source=bootstrap/workflow.sh
. "${BOOTSTRAP_DIR}/workflow.sh"

main() {
  parse_args "$@"
  setup_colors
  validate_manifests
  validate_tool_filters
  expand_tool_dependencies

  if [[ $LIST_TOOLS -eq 1 ]]; then
    list_manifest_tools
    return 0
  fi

  CURRENT_OS="$(detect_os)"
  case "$CURRENT_OS" in
    macos|ubuntu) ;;
    unsupported-linux) echo "Only Ubuntu/Debian Linux is supported by bootstrap.sh." >&2; return 1 ;;
    *) echo "Unsupported operating system." >&2; return 1 ;;
  esac

  if [[ $DRY_RUN -eq 1 ]]; then
    print_install_plan
    return 0
  fi

  refresh_command_paths
  ensure_npm_user_prefix
  if [[ $UPDATE_ONLY -eq 1 ]]; then
    print_status_header INFO "Updating managed tools only."
    printf '  Dotfile relinking, Git identity setup, and default shell changes will be skipped.\n'
  fi

  case "$CURRENT_OS" in
    macos) install_packages_macos ;;
    ubuntu) install_packages_ubuntu ;;
  esac
  ensure_npm_user_prefix

  run_optional_step "Shell framework" install_shell_framework
  if [[ "$CURRENT_OS" == macos ]]; then
    run_optional_step "Meslo font" install_meslo_fonts "${HOME}/Library/Fonts"
  else
    run_optional_step "Meslo font" install_meslo_fonts "${HOME}/.local/share/fonts"
  fi

  install_manifest_npm_tools
  install_lark_skills

  if [[ $UPDATE_ONLY -eq 0 ]]; then
    ensure_codex_xauthority_bridge
    "${DOTFILES_DIR}/install.sh"
    configure_git_identity
    set_default_shell_to_zsh
  fi

  print_post_install_notes
  if ! print_bootstrap_result; then
    return 1
  fi
  [[ $UPDATE_ONLY -eq 1 ]] || print_status_header NEXT "Restart your terminal before using the updated shell environment."
}

if [[ "${BOOTSTRAP_SOURCE_ONLY:-0}" -eq 0 ]]; then
  main "$@"
fi
