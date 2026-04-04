#!/usr/bin/env zsh

set -euo pipefail

DOTFILES_DIR="${0:A:h}"

mkdir -p "$HOME/.config"
mkdir -p "$HOME/.config/zsh/local"
mkdir -p "$HOME/.codex-home"

ln -sfn "$HOME/.Xauthority" "$HOME/.codex-home/.Xauthority"

ln -sfn "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"
ln -sfn "$DOTFILES_DIR/zsh/.zprofile" "$HOME/.zprofile"
ln -sfn "$DOTFILES_DIR/zsh/.p10k.zsh" "$HOME/.p10k.zsh"
ln -sfn "$DOTFILES_DIR/config/zsh/path.zsh" "$HOME/.config/zsh/path.zsh"
ln -sfn "$DOTFILES_DIR/tmux/.tmux.conf" "$HOME/.tmux.conf"
ln -sfn "$DOTFILES_DIR/tmux" "$HOME/.config/tmux"
if [[ -e "$HOME/.config/git" && ! -L "$HOME/.config/git" ]]; then
  rm -rf "$HOME/.config/git"
fi
if [[ -e "$HOME/.config/nvim" && ! -L "$HOME/.config/nvim" ]]; then
  rm -rf "$HOME/.config/nvim"
fi
if [[ -e "$HOME/.config/yazi" && ! -L "$HOME/.config/yazi" ]]; then
  rm -rf "$HOME/.config/yazi"
fi
ln -sfn "$DOTFILES_DIR/config/git" "$HOME/.config/git"
ln -sfn "$DOTFILES_DIR/config/nvim" "$HOME/.config/nvim"
ln -sfn "$DOTFILES_DIR/config/yazi" "$HOME/.config/yazi"

if command -v ya >/dev/null 2>&1; then
  (cd "$HOME/.config/yazi" && ya pkg install)
fi

echo "linked dotfiles from $DOTFILES_DIR"
