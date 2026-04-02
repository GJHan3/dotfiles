# dotfiles

This repository stores personal shell and editor configuration for this machine.

## Layout

- `zsh/`: zsh and Powerlevel10k config
- `tmux/.tmux.conf`: tmux settings
- `config/git/ignore`: global git ignores
- `config/nvim/`: Neovim config
- `config/yazi/`: Yazi file manager config
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

By default, `bootstrap.sh` skips tools that are already installed. Use `--force` to reinstall or refresh managed tools:

```sh
~/dotfiles/bootstrap.sh --force
```

`bootstrap.sh` can:

- install `git`, `zsh`, `tmux`, `neovim`, `ripgrep`, `fd`, `fzf`, `lazygit`, `yazi`, `node`, `codex`, `lark-cli`, `cc-connect`
- install `oh-my-zsh` and `powerlevel10k`
- install Meslo Nerd Font
- relink dotfiles into place
- optionally configure global Git identity
- optionally switch the default shell to `zsh`

After bootstrap, run `codex` or `codex login` once to authenticate the Codex CLI.
Bootstrap also runs `npx skills add larksuite/cli -g -y` for the Feishu/Lark CLI.
Then run `lark-cli config init --new`, and optionally `lark-cli auth login`.
`cc-connect` is also installed via npm; run `cc-connect --help` to verify the command on a new machine.

Private secrets should live in `~/.zsh.secrets` and should not be committed.

## Cross-platform notes

- `zsh/.zprofile` auto-detects Homebrew on macOS and Linuxbrew on Linux.
- Machine-specific overrides can go in `~/.config/zsh/local/*.zsh`.
- Private environment variables can go in `~/.zsh.secrets`.
- `bootstrap.sh` supports macOS and Ubuntu/Debian.
- npm-based CLI installs in `bootstrap.sh` use `https://registry.npmmirror.com`.

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
- `~/.config/yazi`
