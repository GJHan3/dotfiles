# dotfiles

This repository stores personal shell and editor configuration for this machine.

## Layout

- `zsh/`: zsh and Powerlevel10k config
- `tmux/.tmux.conf`: tmux settings
- `config/git/ignore`: global git ignores
- `config/nvim/`: Neovim config
- `bootstrap.sh`: install dependencies and shell tooling on a new machine
- `install.sh`: relink managed files into `$HOME` and `~/.config`

## Usage

Run:

```sh
~/dotfiles/install.sh
```

For a fresh macOS or Ubuntu machine, run:

```sh
~/dotfiles/bootstrap.sh
```

`bootstrap.sh` can:

- install `git`, `zsh`, `tmux`, `neovim`, `ripgrep`, `fd`, `fzf`, `lazygit`, `yazi`, `node`
- install `oh-my-zsh` and `powerlevel10k`
- install Meslo Nerd Font
- relink dotfiles into place
- optionally configure global Git identity
- optionally switch the default shell to `zsh`

Private secrets should live in `~/.zsh.secrets` and should not be committed.

## Cross-platform notes

- `zsh/.zprofile` auto-detects Homebrew on macOS and Linuxbrew on Linux.
- Machine-specific overrides can go in `~/.config/zsh/local/*.zsh`.
- Private environment variables can go in `~/.zsh.secrets`.
- `bootstrap.sh` supports macOS and Ubuntu/Debian.

## Tool notes

- [docs/yazi.md](/Users/hanguangjiang/dotfiles/docs/yazi.md): `yazi` launcher and common file-manager shortcuts
- [docs/shortcuts.md](/Users/hanguangjiang/dotfiles/docs/shortcuts.md): shortcut cheat sheet for Yazi, Neovim, and Tmux

## Managed links

- `~/.zshrc`
- `~/.zprofile`
- `~/.p10k.zsh`
- `~/.tmux.conf`
- `~/.config/git`
- `~/.config/nvim`
