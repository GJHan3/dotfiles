#!/usr/bin/env bash

latest_github_version() {
  curl -fsSL "$1" | sed -n 's/.*"tag_name":[[:space:]]*"v\{0,1\}\([^"]*\)".*/\1/p' | head -n 1
}

install_neovim_ubuntu() {
  local arch archive_name download_url tmp_archive install_dir
  should_install_cmd nvim || return 0
  arch="$(detect_arch)" || return 1
  case "$arch" in
    x86_64) archive_name=nvim-linux-x86_64.tar.gz ;;
    arm64) archive_name=nvim-linux-arm64.tar.gz ;;
    *) echo "Skipping Neovim install: unsupported architecture $(uname -m)" >&2; return 1 ;;
  esac
  download_url="https://github.com/neovim/neovim/releases/download/stable/${archive_name}"
  tmp_archive="/tmp/${archive_name}"
  install_dir="${HOME}/.local/opt/nvim-linux-${arch}"
  curl -fL "$download_url" -o "$tmp_archive" || return 1
  rm -rf "$install_dir" || return 1
  mkdir -p "${HOME}/.local/opt" "${HOME}/.local/bin" || return 1
  tar -C "${HOME}/.local/opt" -xzf "$tmp_archive" || return 1
  ln -sfn "${install_dir}/bin/nvim" "${HOME}/.local/bin/nvim" || return 1
}

install_lazygit_ubuntu() {
  local arch suffix version archive_name tmp_archive tmp_dir
  should_install_cmd lazygit || return 0
  arch="$(detect_arch)" || return 1
  case "$arch" in
    x86_64) suffix=x86_64 ;;
    arm64) suffix=arm64 ;;
    *) echo "Skipping LazyGit: unsupported architecture $(uname -m)" >&2; return 1 ;;
  esac
  version="$(latest_github_version https://api.github.com/repos/jesseduffield/lazygit/releases/latest)" || return 1
  [[ "$version" =~ ^[0-9]+(\.[0-9]+)*$ ]] || { echo "Failed to detect a safe latest LazyGit version." >&2; return 1; }
  archive_name="lazygit_${version}_linux_${suffix}.tar.gz"
  tmp_archive="/tmp/${archive_name}"
  tmp_dir="/tmp/lazygit-${version}-${arch}"
  curl -fL "https://github.com/jesseduffield/lazygit/releases/download/v${version}/${archive_name}" -o "$tmp_archive" || return 1
  rm -rf "$tmp_dir" || return 1
  mkdir -p "$tmp_dir" || return 1
  tar -C "$tmp_dir" -xzf "$tmp_archive" lazygit || return 1
  mkdir -p "${HOME}/.local/bin" || return 1
  install -m 0755 "$tmp_dir/lazygit" "${HOME}/.local/bin/lazygit" || return 1
}

install_yazi_ubuntu() {
  local arch version archive_name tmp_archive tmp_dir
  should_install_cmd yazi || return 0
  arch="$(detect_arch)" || return 1
  case "$arch" in
    x86_64) archive_name=yazi-x86_64-unknown-linux-musl.zip ;;
    arm64) archive_name=yazi-aarch64-unknown-linux-musl.zip ;;
    *) echo "Skipping Yazi: unsupported architecture $(uname -m)" >&2; return 1 ;;
  esac
  version="$(latest_github_version https://api.github.com/repos/sxyazi/yazi/releases/latest)" || return 1
  [[ "$version" =~ ^[0-9]+(\.[0-9]+)*$ ]] || { echo "Failed to detect a safe latest Yazi version." >&2; return 1; }
  tmp_archive="/tmp/${archive_name}"
  tmp_dir="/tmp/yazi-${version}-${arch}"
  curl -fL "https://github.com/sxyazi/yazi/releases/download/v${version}/${archive_name}" -o "$tmp_archive" || return 1
  rm -rf "$tmp_dir" || return 1
  mkdir -p "$tmp_dir" || return 1
  unzip -q "$tmp_archive" -d "$tmp_dir" || return 1
  mkdir -p "${HOME}/.local/bin" || return 1
  install -m 0755 "$tmp_dir"/yazi-*/yazi "${HOME}/.local/bin/yazi" || return 1
  install -m 0755 "$tmp_dir"/yazi-*/ya "${HOME}/.local/bin/ya" || return 1
}

install_stylua_ubuntu() {
  local arch version archive_name tmp_archive tmp_dir
  should_install_cmd stylua || return 0
  arch="$(detect_arch)" || return 1
  case "$arch" in
    x86_64) archive_name=stylua-linux-x86_64-musl.zip ;;
    arm64) archive_name=stylua-linux-aarch64-musl.zip ;;
    *) echo "Skipping StyLua: unsupported architecture $(uname -m)" >&2; return 1 ;;
  esac
  version="$(latest_github_version https://api.github.com/repos/JohnnyMorganz/StyLua/releases/latest)" || return 1
  [[ "$version" =~ ^[0-9]+(\.[0-9]+)*$ ]] || { echo "Failed to detect a safe latest StyLua version." >&2; return 1; }
  tmp_archive="/tmp/${archive_name}"
  tmp_dir="/tmp/stylua-${version}-${arch}"
  curl -fL "https://github.com/JohnnyMorganz/StyLua/releases/download/v${version}/${archive_name}" -o "$tmp_archive" || return 1
  rm -rf "$tmp_dir" || return 1
  mkdir -p "$tmp_dir" || return 1
  unzip -q "$tmp_archive" -d "$tmp_dir" || return 1
  mkdir -p "${HOME}/.local/bin" || return 1
  install -m 0755 "$tmp_dir/stylua" "${HOME}/.local/bin/stylua" || return 1
}
