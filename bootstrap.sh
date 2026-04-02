#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OH_MY_ZSH_DIR="${HOME}/.oh-my-zsh"
P10K_DIR="${OH_MY_ZSH_DIR}/custom/themes/powerlevel10k"
INTERACTIVE=0
FORCE_INSTALL=0
NPM_REGISTRY="https://registry.npmmirror.com"

if [[ -t 0 && -t 1 ]]; then
  INTERACTIVE=1
fi

need_cmd() {
  command -v "$1" >/dev/null 2>&1
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

install_codex_cli() {
  if ! should_install_cmd codex; then
    return
  fi

  if ! need_cmd npm; then
    echo "Skipping Codex CLI install: npm is not available." >&2
    return 1
  fi

  if npm i -g @openai/codex@latest --registry="$NPM_REGISTRY"; then
    return
  fi

  if need_cmd sudo; then
    sudo npm i -g @openai/codex@latest --registry="$NPM_REGISTRY"
    return
  fi

  echo "Failed to install Codex CLI with npm." >&2
  return 1
}

install_lark_cli() {
  if ! should_install_cmd lark-cli; then
    return
  fi

  if ! need_cmd npm; then
    echo "Skipping Lark CLI install: npm is not available." >&2
    return 1
  fi

  if npm i -g @larksuite/cli --registry="$NPM_REGISTRY"; then
    return
  fi

  if need_cmd sudo; then
    sudo npm i -g @larksuite/cli --registry="$NPM_REGISTRY"
    return
  fi

  echo "Failed to install Lark CLI with npm." >&2
  return 1
}

install_cc_connect() {
  if ! should_install_cmd cc-connect; then
    return
  fi

  if ! need_cmd npm; then
    echo "Skipping cc-connect install: npm is not available." >&2
    return 1
  fi

  if npm i -g cc-connect --registry="$NPM_REGISTRY"; then
    return
  fi

  if need_cmd sudo; then
    sudo npm i -g cc-connect --registry="$NPM_REGISTRY"
    return
  fi

  echo "Failed to install cc-connect with npm." >&2
  return 1
}

install_lark_skills() {
  if ! need_cmd npx; then
    echo "Skipping Lark skills install: npx is not available." >&2
    return 1
  fi

  npx skills add larksuite/cli -g -y
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

  if [[ -x /opt/homebrew/bin/brew ]]; then
    brew_bin=/opt/homebrew/bin/brew
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
}

install_packages_ubuntu() {
  local -a APT_PACKAGES=()

  remove_stale_lazygit_ppa

  append_apt_package_if_missing git
  append_apt_package_if_missing zsh
  append_apt_package_if_missing tmux
  append_apt_package_if_missing curl
  append_apt_package_if_missing fzf
  append_apt_package_if_missing ripgrep
  append_apt_package_if_missing fd-find
  append_apt_package_if_missing xclip
  append_apt_package_if_missing nodejs
  append_apt_package_if_missing npm
  append_apt_package_if_missing build-essential
  append_apt_package_if_missing unzip
  append_apt_package_if_missing software-properties-common
  append_apt_package_if_missing fontconfig
  append_apt_package_if_missing file

  if (( ${#APT_PACKAGES[@]} > 0 )); then
    sudo apt-get update
    sudo apt-get install -y "${APT_PACKAGES[@]}"
  fi

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
    reply="${reply:-Y}"
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
    cat <<'EOF'
Note: Codex CLI is installed.
Run `codex` or `codex login` to sign in with your ChatGPT account or API key.
EOF
  fi

  if need_cmd lark-cli; then
    cat <<'EOF'
Note: Lark CLI is installed.
Run `lark-cli config init --new`.
If you want user-level access, also run `lark-cli auth login`.
EOF
  fi

  if need_cmd cc-connect; then
    cat <<'EOF'
Note: cc-connect is installed.
Run `cc-connect --help` to verify the command and see available setup options.
EOF
  fi

  if ! need_cmd claude; then
    cat <<'EOF'
Note: `claude` is not installed.
Your Neovim ClaudeCode plugin is configured to run the `claude` command, so install it
manually on machines where you want that workflow.
EOF
  fi

  cat <<'EOF'
If Powerlevel10k icons still look wrong, set your terminal font to:
  MesloLGS NF
EOF
}

main() {
  local os
  parse_args "$@"
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

  if [[ "$os" == "macos" ]]; then
    install_meslo_fonts_macos
  else
    install_meslo_fonts_ubuntu
  fi

  install_codex_cli
  install_lark_cli
  install_cc_connect
  if need_cmd lark-cli; then
    install_lark_skills
  fi

  "${DOTFILES_DIR}/install.sh"
  configure_git_identity
  set_default_shell_to_zsh
  print_post_install_notes

  cat <<'EOF'
Bootstrap complete.
Restart your terminal after bootstrap completes.
EOF
}

main "$@"
