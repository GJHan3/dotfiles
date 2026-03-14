#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OH_MY_ZSH_DIR="${HOME}/.oh-my-zsh"
P10K_DIR="${OH_MY_ZSH_DIR}/custom/themes/powerlevel10k"
INTERACTIVE=0

if [[ -t 0 && -t 1 ]]; then
  INTERACTIVE=1
fi

need_cmd() {
  command -v "$1" >/dev/null 2>&1
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
  install_homebrew

  local brew_bin
  if [[ -x /opt/homebrew/bin/brew ]]; then
    brew_bin=/opt/homebrew/bin/brew
  else
    brew_bin="$(command -v brew)"
  fi

  "$brew_bin" install git zsh tmux neovim curl fzf ripgrep fd lazygit node
}

install_packages_ubuntu() {
  remove_stale_lazygit_ppa
  sudo apt-get update
  sudo apt-get install -y git zsh tmux curl fzf ripgrep fd-find xclip nodejs npm build-essential unzip software-properties-common fontconfig

  if ! need_cmd fd && [[ -x /usr/bin/fdfind ]]; then
    sudo ln -sf /usr/bin/fdfind /usr/local/bin/fd
  fi

  install_neovim_ubuntu
  install_lazygit_ubuntu

}

clone_or_update_repo() {
  local repo_url=$1
  local target_dir=$2

  if [[ -d "${target_dir}/.git" ]]; then
    git -C "$target_dir" pull --ff-only
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
  mkdir -p "${HOME}/Library/Fonts"

  curl -fsSL https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf -o "${HOME}/Library/Fonts/MesloLGS NF Regular.ttf"
  curl -fsSL https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf -o "${HOME}/Library/Fonts/MesloLGS NF Bold.ttf"
  curl -fsSL https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf -o "${HOME}/Library/Fonts/MesloLGS NF Italic.ttf"
  curl -fsSL https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf -o "${HOME}/Library/Fonts/MesloLGS NF Bold Italic.ttf"
}

install_meslo_fonts_ubuntu() {
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
