#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OH_MY_ZSH_DIR="${HOME}/.oh-my-zsh"
P10K_DIR="${OH_MY_ZSH_DIR}/custom/themes/powerlevel10k"
ZSH_CUSTOM_DIR="${OH_MY_ZSH_DIR}/custom"
ZSH_AUTOSUGGESTIONS_DIR="${ZSH_CUSTOM_DIR}/plugins/zsh-autosuggestions"
ZSH_SYNTAX_HIGHLIGHTING_DIR="${ZSH_CUSTOM_DIR}/plugins/zsh-syntax-highlighting"
INTERACTIVE=0
FORCE_INSTALL=0
NPM_REGISTRY="https://registry.npmmirror.com"
NPM_FALLBACK_REGISTRY="https://registry.npmjs.org"
NODESOURCE_NODE_MAJOR="22"
NODESOURCE_KEYRING="/usr/share/keyrings/nodesource.gpg"
NODESOURCE_SOURCE_FILE="/etc/apt/sources.list.d/nodesource.sources"
MACFUSE_CASK="macfuse"
SSHFS_MACOS_VERSION="3.7.5"
SSHFS_MACOS_URL="https://github.com/libfuse/sshfs/releases/download/sshfs-${SSHFS_MACOS_VERSION}/sshfs-${SSHFS_MACOS_VERSION}.pkg"

if [[ -t 0 && -t 1 ]]; then
  INTERACTIVE=1
fi

COLOR_RESET=""
COLOR_BOLD=""
COLOR_NEXT=""
COLOR_WARN=""
COLOR_INFO=""
COLOR_DONE=""
COLOR_COMMAND=""

setup_colors() {
  if [[ -t 1 ]] && [[ -z "${NO_COLOR:-}" ]]; then
    COLOR_RESET="$(printf "\\033[0m")"
    COLOR_BOLD="$(printf "\\033[1m")"
    COLOR_NEXT="$(printf "\\033[1;36m")"
    COLOR_WARN="$(printf "\\033[1;33m")"
    COLOR_INFO="$(printf "\\033[1;34m")"
    COLOR_DONE="$(printf "\033[1;32m")"
    COLOR_COMMAND="$(printf "\033[1;7m")"
  fi
}

print_status_header() {
  local level=$1
  local title=$2
  local color=$COLOR_INFO

  case "$level" in
    NEXT) color=$COLOR_NEXT ;;
    WARN) color=$COLOR_WARN ;;
    INFO) color=$COLOR_INFO ;;
    DONE) color=$COLOR_DONE ;;
  esac

  printf "\n%s[%s]%s %s%s%s\n" "$color" "$level" "$COLOR_RESET" "$COLOR_BOLD" "$title" "$COLOR_RESET"
}

print_command_hint() {
  local label=$1
  local command=$2

  printf "  %s %s%s%s\n" "$label" "$COLOR_COMMAND" "$command" "$COLOR_RESET"
}

print_missing_command_warning() {
  local title=$1
  local command_name=$2
  local detail=$3
  local hint=${4:-}

  print_status_header WARN "${title} missing"
  printf "  Command not found: %s\n" "$command_name"
  printf "  %s\n" "$detail"
  if [[ -n "$hint" ]]; then
    print_command_hint "Check:" "$hint"
  fi
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1
}

prepend_path_if_dir() {
  local dir=$1

  if [[ ! -d "$dir" ]]; then
    return
  fi

  case ":${PATH}:" in
    *":${dir}:"*) ;;
    *) PATH="${dir}:${PATH}" ;;
  esac
}

refresh_command_paths() {
  local brew_bin npm_prefix

  for brew_bin in \
    /opt/homebrew/bin/brew \
    /usr/local/bin/brew \
    /home/linuxbrew/.linuxbrew/bin/brew; do
    if [[ -x "$brew_bin" ]]; then
      eval "$("$brew_bin" shellenv 2>/dev/null)"
      break
    fi
  done

  prepend_path_if_dir "${HOME}/.local/bin"
  prepend_path_if_dir "${HOME}/bin"
  prepend_path_if_dir "${HOME}/.npm-global/bin"

  if need_cmd npm; then
    npm_prefix="$(npm config get prefix 2>/dev/null || true)"
    if [[ -n "$npm_prefix" ]] && [[ "$npm_prefix" != "undefined" ]]; then
      prepend_path_if_dir "${npm_prefix}/bin"
    fi
  fi

  hash -r 2>/dev/null || true
}

need_apt_package() {
  dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -qx 'install ok installed'
}

should_install_cmd() {
  local cmd=$1
  [[ $FORCE_INSTALL -eq 1 ]] || ! need_cmd "$cmd"
}

should_install_apt_package() {
  local package=$1
  [[ $FORCE_INSTALL -eq 1 ]] || ! need_apt_package "$package"
}

should_update_existing() {
  [[ $FORCE_INSTALL -eq 1 ]]
}

append_formula_if_missing() {
  local formula=$1
  local cmd=${2:-$formula}

  if should_install_cmd "$cmd"; then
    FORMULAE+=("$formula")
  fi
}

append_apt_package_if_missing() {
  local package=$1

  if should_install_apt_package "$package"; then
    APT_PACKAGES+=("$package")
  fi
}

need_macos_pkg() {
  pkgutil --pkgs "$1" >/dev/null 2>&1
}

usage() {
  cat <<'EOF'
Usage: ./bootstrap.sh [--force]

Options:
  --force     Reinstall or update managed tools even if they already exist.
  -h, --help  Show this help message.
EOF
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --force)
        FORCE_INSTALL=1
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        echo "Unknown option: $1" >&2
        usage >&2
        exit 1
        ;;
    esac
    shift
  done
}

detect_arch() {
  case "$(uname -m)" in
    x86_64|amd64) echo "x86_64" ;;
    aarch64|arm64) echo "arm64" ;;
    *) echo "unsupported" ;;
  esac
}

remove_stale_lazygit_ppa() {
  local source_file="/etc/apt/sources.list.d/lazygit-team-ubuntu-release-jammy.list"

  if [[ -f "$source_file" ]]; then
    sudo rm -f "$source_file"
  fi
}

install_nodesource_ubuntu() {
  local arch key_url source_url

  if [[ $FORCE_INSTALL -eq 0 ]] && [[ -f "$NODESOURCE_SOURCE_FILE" ]] && [[ -f "$NODESOURCE_KEYRING" ]] && grep -q "node_${NODESOURCE_NODE_MAJOR}\.x" "$NODESOURCE_SOURCE_FILE"; then
    return
  fi

  arch="$(dpkg --print-architecture)"
  key_url="https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key"
  source_url="https://deb.nodesource.com/node_${NODESOURCE_NODE_MAJOR}.x"

  sudo apt-get update
  sudo apt-get install -y ca-certificates gnupg
  sudo mkdir -p "$(dirname "$NODESOURCE_KEYRING")" "$(dirname "$NODESOURCE_SOURCE_FILE")"
  curl -fsSL "$key_url" | sudo gpg --dearmor --yes -o "$NODESOURCE_KEYRING"
  sudo chmod 0644 "$NODESOURCE_KEYRING"

  cat <<EOF | sudo tee "$NODESOURCE_SOURCE_FILE" >/dev/null
Types: deb
URIs: ${source_url}
Suites: nodistro
Components: main
Architectures: ${arch}
Signed-By: ${NODESOURCE_KEYRING}
EOF
}

install_neovim_ubuntu() {
  local arch archive_name download_url tmp_archive install_dir

  if ! should_install_cmd nvim; then
    return
  fi

  arch="$(detect_arch)"
  case "$arch" in
    x86_64) archive_name="nvim-linux-x86_64.tar.gz" ;;
    arm64) archive_name="nvim-linux-arm64.tar.gz" ;;
    *)
      echo "Skipping Neovim install: unsupported architecture $(uname -m)" >&2
      return
      ;;
  esac

  download_url="https://github.com/neovim/neovim/releases/download/stable/${archive_name}"
  tmp_archive="/tmp/${archive_name}"
  install_dir="/opt/nvim-linux-${arch}"

  curl -fL "$download_url" -o "$tmp_archive"
  sudo rm -rf "$install_dir"
  sudo tar -C /opt -xzf "$tmp_archive"
  sudo ln -sf "${install_dir}/bin/nvim" /usr/local/bin/nvim
}

install_lazygit_ubuntu() {
  local arch api_url version archive_name archive_name_suffix download_url tmp_archive tmp_dir

  if ! should_install_cmd lazygit; then
    return
  fi

  arch="$(detect_arch)"
  case "$arch" in
    x86_64) archive_name_suffix="x86_64" ;;
    arm64) archive_name_suffix="arm64" ;;
    *)
      echo "Skipping lazygit install: unsupported architecture $(uname -m)" >&2
      return
      ;;
  esac

  api_url="https://api.github.com/repos/jesseduffield/lazygit/releases/latest"
  version="$(
    curl -fsSL "$api_url" | sed -n 's/.*"tag_name":[[:space:]]*"v\([^"]*\)".*/\1/p' | head -n 1
  )"

  if [[ -z "$version" ]]; then
    echo "Failed to detect latest lazygit version." >&2
    return 1
  fi

  archive_name="lazygit_${version}_linux_${archive_name_suffix}.tar.gz"
  download_url="https://github.com/jesseduffield/lazygit/releases/download/v${version}/${archive_name}"
  tmp_archive="/tmp/${archive_name}"
  tmp_dir="/tmp/lazygit-${version}-${arch}"

  curl -fL "$download_url" -o "$tmp_archive"
  rm -rf "$tmp_dir"
  mkdir -p "$tmp_dir"
  tar -C "$tmp_dir" -xzf "$tmp_archive" lazygit
  sudo install "$tmp_dir/lazygit" /usr/local/bin/lazygit
}

install_yazi_ubuntu() {
  local arch api_url version archive_name download_url tmp_archive tmp_dir

  if ! should_install_cmd yazi; then
    return
  fi

  arch="$(detect_arch)"
  case "$arch" in
    # Prefer musl builds on Debian/Ubuntu to avoid host glibc version mismatches.
    x86_64) archive_name="yazi-x86_64-unknown-linux-musl.zip" ;;
    arm64) archive_name="yazi-aarch64-unknown-linux-musl.zip" ;;
    *)
      echo "Skipping yazi install: unsupported architecture $(uname -m)" >&2
      return
      ;;
  esac

  api_url="https://api.github.com/repos/sxyazi/yazi/releases/latest"
  version="$(
    curl -fsSL "$api_url" | sed -n 's/.*"tag_name":[[:space:]]*"v\([^"]*\)".*/\1/p' | head -n 1
  )"

  if [[ -z "$version" ]]; then
    echo "Failed to detect latest yazi version." >&2
    return 1
  fi

  download_url="https://github.com/sxyazi/yazi/releases/download/v${version}/${archive_name}"
  tmp_archive="/tmp/${archive_name}"
  tmp_dir="/tmp/yazi-${version}-${arch}"

  curl -fL "$download_url" -o "$tmp_archive"
  rm -rf "$tmp_dir"
  mkdir -p "$tmp_dir"
  unzip -q "$tmp_archive" -d "$tmp_dir"

  sudo install "$tmp_dir"/yazi-*/yazi /usr/local/bin/yazi
  sudo install "$tmp_dir"/yazi-*/ya /usr/local/bin/ya
}

install_stylua_ubuntu() {
  local arch api_url version archive_name download_url tmp_archive tmp_dir

  if ! should_install_cmd stylua; then
    return
  fi

  arch="$(detect_arch)"
  case "$arch" in
    x86_64) archive_name="stylua-linux-x86_64-musl.zip" ;;
    arm64) archive_name="stylua-linux-aarch64-musl.zip" ;;
    *)
      echo "Skipping stylua install: unsupported architecture $(uname -m)" >&2
      return
      ;;
  esac

  api_url="https://api.github.com/repos/JohnnyMorganz/StyLua/releases/latest"
  version="$(
    curl -fsSL "$api_url" | sed -n 's/.*"tag_name":[[:space:]]*"v\{0,1\}\([^"]*\)".*/\1/p' | head -n 1
  )"

  if [[ -z "$version" ]]; then
    echo "Failed to detect latest stylua version." >&2
    return 1
  fi

  download_url="https://github.com/JohnnyMorganz/StyLua/releases/download/v${version}/${archive_name}"
  tmp_archive="/tmp/${archive_name}"
  tmp_dir="/tmp/stylua-${version}-${arch}"

  curl -fL "$download_url" -o "$tmp_archive"
  rm -rf "$tmp_dir"
  mkdir -p "$tmp_dir"
  unzip -q "$tmp_archive" -d "$tmp_dir"

  sudo install "$tmp_dir/stylua" /usr/local/bin/stylua
}

run_npm_global_install() {
  local package=$1
  local registry=$2

  npm i -g "$package" --registry="$registry"
}

install_npm_global_package() {
  local package=$1
  local label=$2
  local registry

  refresh_command_paths

  if ! need_cmd npm; then
    echo "Skipping ${label} install: npm is not available." >&2
    return 1
  fi

  for registry in "$NPM_REGISTRY" "$NPM_FALLBACK_REGISTRY"; do
    if run_npm_global_install "$package" "$registry"; then
      refresh_command_paths
      return 0
    fi
  done

  if need_cmd sudo; then
    for registry in "$NPM_REGISTRY" "$NPM_FALLBACK_REGISTRY"; do
      if sudo npm i -g "$package" --registry="$registry"; then
        refresh_command_paths
        return 0
      fi
    done
  fi

  echo "Failed to install ${label} with npm." >&2
  return 1
}

install_codex_cli() {
  if ! should_install_cmd codex; then
    return
  fi

  if ! install_npm_global_package "@openai/codex@latest" "Codex CLI"; then
    echo "Continuing without Codex CLI." >&2
  fi
}

install_opencode_cli() {
  if ! should_install_cmd opencode; then
    return
  fi

  if ! install_npm_global_package "opencode-ai" "OpenCode CLI"; then
    echo "Continuing without OpenCode CLI." >&2
  fi
}

install_lark_cli() {
  if ! should_install_cmd lark-cli; then
    return
  fi

  if ! install_npm_global_package "@larksuite/cli" "Lark CLI"; then
    echo "Continuing without Lark CLI." >&2
  fi
}

install_cc_connect() {
  if ! should_install_cmd cc-connect; then
    return
  fi

  if ! install_npm_global_package "cc-connect" "cc-connect"; then
    echo "Continuing without cc-connect." >&2
  fi
}

ensure_codex_xauthority_bridge() {
  mkdir -p "${HOME}/.codex-home"
  ln -sfn "${HOME}/.Xauthority" "${HOME}/.codex-home/.Xauthority"
}

install_lark_skills() {
  if ! need_cmd npx; then
    echo "Skipping Lark skills install: npx is not available." >&2
    return 0
  fi

  if ! npx -y skills add larksuite/cli -g -y; then
    echo "Skipping Lark skills install: npx skills add failed." >&2
  fi
}

detect_os() {
  case "$(uname -s)" in
    Darwin) echo "macos" ;;
    Linux)
      if [[ -r /etc/os-release ]]; then
        . /etc/os-release
        case "${ID:-}" in
          ubuntu|debian) echo "ubuntu" ;;
          *) echo "unsupported-linux" ;;
        esac
      else
        echo "unsupported-linux"
      fi
      ;;
    *) echo "unsupported" ;;
  esac
}

install_homebrew() {
  if need_cmd brew; then
    return
  fi

  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
}

install_packages_macos() {
  local brew_bin
  local -a FORMULAE=()

  install_homebrew
  refresh_command_paths

  if [[ -x /opt/homebrew/bin/brew ]]; then
    brew_bin=/opt/homebrew/bin/brew
  elif [[ -x /usr/local/bin/brew ]]; then
    brew_bin=/usr/local/bin/brew
  else
    brew_bin="$(command -v brew)"
  fi

  append_formula_if_missing git
  append_formula_if_missing zsh
  append_formula_if_missing tmux
  append_formula_if_missing neovim nvim
  append_formula_if_missing curl
  append_formula_if_missing fzf
  append_formula_if_missing ripgrep rg
  append_formula_if_missing fd
  append_formula_if_missing lazygit
  append_formula_if_missing node
  append_formula_if_missing stylua
  append_formula_if_missing yazi

  if (( ${#FORMULAE[@]} > 0 )); then
    "$brew_bin" install "${FORMULAE[@]}"
  fi

  refresh_command_paths

  install_im_select_macos "$brew_bin"
  install_sshfs_macos "$brew_bin"
}

install_im_select_macos() {
  local brew_bin=$1

  if ! should_install_cmd im-select; then
    return
  fi

  "$brew_bin" tap daipeihust/tap
  "$brew_bin" install im-select
  refresh_command_paths
}

install_sshfs_macos() {
  local brew_bin=$1
  local macfuse_dmg mount_point sshfs_pkg

  if [[ $FORCE_INSTALL -eq 1 ]] || ! need_macos_pkg io.macfuse.installer.components.core; then
    "$brew_bin" install --cask "$MACFUSE_CASK"
  fi

  if [[ $FORCE_INSTALL -eq 1 ]] || ! need_cmd sshfs; then
    sshfs_pkg="/tmp/sshfs-${SSHFS_MACOS_VERSION}.pkg"
    curl -fL "$SSHFS_MACOS_URL" -o "$sshfs_pkg"
    sudo /usr/sbin/installer -pkg "$sshfs_pkg" -target /
  fi

  # Best effort cleanup for cask cache mounts if the brew install left them attached.
  macfuse_dmg="$("$brew_bin" --cache --cask "$MACFUSE_CASK" 2>/dev/null || true)"
  if [[ -n "$macfuse_dmg" ]]; then
    mount_point="$(hdiutil info | awk -v dmg="$macfuse_dmg" '$0 ~ dmg {found=1} found && /\/Volumes\// {print $1; exit}')"
    if [[ -n "$mount_point" ]]; then
      hdiutil detach "$mount_point" >/dev/null 2>&1 || true
    fi
  fi
}

install_packages_ubuntu() {
  local -a APT_PACKAGES=()

  remove_stale_lazygit_ppa
  install_nodesource_ubuntu

  append_apt_package_if_missing git
  append_apt_package_if_missing zsh
  append_apt_package_if_missing tmux
  append_apt_package_if_missing curl
  append_apt_package_if_missing fzf
  append_apt_package_if_missing ripgrep
  append_apt_package_if_missing fd-find
  append_apt_package_if_missing xclip
  append_apt_package_if_missing nodejs
  append_apt_package_if_missing build-essential
  append_apt_package_if_missing unzip
  append_apt_package_if_missing sshfs
  append_apt_package_if_missing software-properties-common
  append_apt_package_if_missing fontconfig
  append_apt_package_if_missing file

  if (( ${#APT_PACKAGES[@]} > 0 )); then
    sudo apt-get update
    sudo apt-get install -y "${APT_PACKAGES[@]}"
  fi

  refresh_command_paths

  if ! need_cmd fd && [[ -x /usr/bin/fdfind ]]; then
    sudo ln -sf /usr/bin/fdfind /usr/local/bin/fd
  fi

  install_neovim_ubuntu
  install_lazygit_ubuntu
  install_stylua_ubuntu
  install_yazi_ubuntu

}

clone_or_update_repo() {
  local repo_url=$1
  local target_dir=$2

  if [[ -d "${target_dir}/.git" ]]; then
    if should_update_existing; then
      git -C "$target_dir" pull --ff-only
    fi
  else
    mkdir -p "$(dirname "$target_dir")"
    git clone --depth=1 "$repo_url" "$target_dir"
  fi
}

install_oh_my_zsh() {
  clone_or_update_repo https://github.com/ohmyzsh/ohmyzsh.git "$OH_MY_ZSH_DIR"
}

install_powerlevel10k() {
  clone_or_update_repo https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
}

install_zsh_plugins() {
  clone_or_update_repo https://github.com/zsh-users/zsh-autosuggestions "$ZSH_AUTOSUGGESTIONS_DIR"
  clone_or_update_repo https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_SYNTAX_HIGHLIGHTING_DIR"
}

install_meslo_fonts_macos() {
  if ! should_update_existing &&
    [[ -f "${HOME}/Library/Fonts/MesloLGS NF Regular.ttf" ]] &&
    [[ -f "${HOME}/Library/Fonts/MesloLGS NF Bold.ttf" ]] &&
    [[ -f "${HOME}/Library/Fonts/MesloLGS NF Italic.ttf" ]] &&
    [[ -f "${HOME}/Library/Fonts/MesloLGS NF Bold Italic.ttf" ]]; then
    return
  fi

  mkdir -p "${HOME}/Library/Fonts"

  curl -fsSL https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf -o "${HOME}/Library/Fonts/MesloLGS NF Regular.ttf"
  curl -fsSL https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf -o "${HOME}/Library/Fonts/MesloLGS NF Bold.ttf"
  curl -fsSL https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf -o "${HOME}/Library/Fonts/MesloLGS NF Italic.ttf"
  curl -fsSL https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf -o "${HOME}/Library/Fonts/MesloLGS NF Bold Italic.ttf"
}

install_meslo_fonts_ubuntu() {
  if ! should_update_existing &&
    [[ -f "${HOME}/.local/share/fonts/MesloLGS NF Regular.ttf" ]] &&
    [[ -f "${HOME}/.local/share/fonts/MesloLGS NF Bold.ttf" ]] &&
    [[ -f "${HOME}/.local/share/fonts/MesloLGS NF Italic.ttf" ]] &&
    [[ -f "${HOME}/.local/share/fonts/MesloLGS NF Bold Italic.ttf" ]]; then
    return
  fi

  mkdir -p "${HOME}/.local/share/fonts"

  curl -fsSL https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf -o "${HOME}/.local/share/fonts/MesloLGS NF Regular.ttf"
  curl -fsSL https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf -o "${HOME}/.local/share/fonts/MesloLGS NF Bold.ttf"
  curl -fsSL https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf -o "${HOME}/.local/share/fonts/MesloLGS NF Italic.ttf"
  curl -fsSL https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf -o "${HOME}/.local/share/fonts/MesloLGS NF Bold Italic.ttf"

  if need_cmd fc-cache; then
    fc-cache -f "${HOME}/.local/share/fonts"
  fi
}

set_default_shell_to_zsh() {
  local zsh_path
  zsh_path="$(command -v zsh)"

  if [[ "${SHELL:-}" == "$zsh_path" ]]; then
    return
  fi

  if [[ $INTERACTIVE -eq 1 ]]; then
    printf "Set default shell to %s? [Y/n] " "$zsh_path"
    read -r reply
    reply=""
    if [[ "$reply" =~ ^[Yy]$ ]]; then
      chsh -s "$zsh_path" || true
    fi
  fi
}

configure_git_identity() {
  local current_name current_email git_name git_email reply
  current_name="$(git config --global user.name || true)"
  current_email="$(git config --global user.email || true)"

  if [[ -n "$current_name" && -n "$current_email" ]]; then
    return
  fi

  if [[ $INTERACTIVE -ne 1 ]]; then
    return
  fi

  printf "Configure global git user.name and user.email now? [Y/n] "
  read -r reply
  reply="${reply:-Y}"
  if [[ ! "$reply" =~ ^[Yy]$ ]]; then
    return
  fi

  if [[ -z "$current_name" ]]; then
    printf "Git user.name: "
    read -r git_name
    if [[ -n "$git_name" ]]; then
      git config --global user.name "$git_name"
    fi
  fi

  if [[ -z "$current_email" ]]; then
    printf "Git user.email: "
    read -r git_email
    if [[ -n "$git_email" ]]; then
      git config --global user.email "$git_email"
    fi
  fi
}

print_post_install_notes() {
  if need_cmd codex; then
    print_status_header NEXT "Codex CLI"
    print_command_hint "Run:" "codex"
    print_command_hint "Or:" "codex login"
    printf "  Sign in with your ChatGPT account or API key.\n"
  else
    print_missing_command_warning \
      "Codex CLI" \
      "codex" \
      "bootstrap.sh could not install it automatically, so Codex terminal workflows stay unavailable until you install it manually." \
      "npm i -g @openai/codex@latest"
  fi

  if need_cmd opencode; then
    print_status_header NEXT "OpenCode CLI"
    print_command_hint "Run:" "opencode"
    print_command_hint "Optional:" "opencode auth login"
    printf "  Sign in with the model provider you want to use, then start a session.\n"
  else
    print_missing_command_warning \
      "OpenCode CLI" \
      "opencode" \
      "bootstrap.sh could not install it automatically, so OpenCode terminal workflows stay unavailable until you install it manually." \
      "npm i -g opencode-ai"
  fi

  if need_cmd lark-cli; then
    print_status_header NEXT "Lark CLI"
    print_command_hint "Run:" "lark-cli config init --new"
    print_command_hint "Optional:" "lark-cli auth login"
    printf "  Use the optional login if you want user-level access.\n"
  else
    print_missing_command_warning \
      "Lark CLI" \
      "lark-cli" \
      "bootstrap.sh could not install it automatically, so Feishu/Lark command workflows will not work yet." \
      "npm i -g @larksuite/cli"
  fi

  if need_cmd cc-connect; then
    print_status_header NEXT "cc-connect"
    print_command_hint "Run:" "cc-connect --help"
    printf "  Verify the command and review available setup options.\n"
  else
    print_missing_command_warning \
      "cc-connect" \
      "cc-connect" \
      "bootstrap.sh could not install it automatically, so the Claude Code connection helper is not ready on this machine." \
      "npm i -g cc-connect"
  fi

  if ! need_cmd claude; then
    print_status_header WARN "ClaudeCode dependency missing"
    printf "  Command not found: claude\n"
    printf '  Your Neovim ClaudeCode plugin expects the `claude` command, so install it\n'
    printf "  manually on machines where you want that workflow.\n"
  fi

  if need_cmd sshfs; then
    print_status_header INFO "SSHFS for Yazi is ready"
    printf "  On macOS, if mounts are blocked, check:\n"
    printf "    System Settings -> Privacy & Security\n"
    printf "  Allow macFUSE if macOS asks for approval.\n"
  fi

  print_status_header INFO "Font"
  printf "  If Powerlevel10k icons still look wrong, set your terminal font to:\n"
  printf "    MesloLGS NF\n"

  if need_cmd zsh; then
    print_status_header INFO "Proxy"
    print_command_hint "Run when needed:" "proxy_on"
    printf "  Proxy is off by default. Use proxy_on only when you want to enable it.\n"
  fi
}

main() {
  local os
  parse_args "$@"
  setup_colors
  refresh_command_paths
  os="$(detect_os)"

  case "$os" in
    macos)
      install_packages_macos
      ;;
    ubuntu)
      install_packages_ubuntu
      ;;
    unsupported-linux)
      echo "Only Ubuntu/Debian Linux is supported by bootstrap.sh." >&2
      exit 1
      ;;
    *)
      echo "Unsupported operating system." >&2
      exit 1
      ;;
  esac

  install_oh_my_zsh
  install_powerlevel10k
  install_zsh_plugins

  if [[ "$os" == "macos" ]]; then
    install_meslo_fonts_macos
  else
    install_meslo_fonts_ubuntu
  fi

  install_codex_cli
  install_opencode_cli
  install_lark_cli
  install_cc_connect
  if need_cmd lark-cli; then
    install_lark_skills
  fi

  ensure_codex_xauthority_bridge
  "${DOTFILES_DIR}/install.sh"
  configure_git_identity
  set_default_shell_to_zsh
  print_post_install_notes

  print_status_header DONE "Bootstrap complete."
  print_status_header NEXT "Restart your terminal before using the updated shell environment."
}

main "$@"
