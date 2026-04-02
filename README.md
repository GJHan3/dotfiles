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

- install `git`, `zsh`, `tmux`, `neovim`, `ripgrep`, `fd`, `fzf`, `lazygit`, `stylua`, `yazi`, `sshfs`, `node`, `codex`, `lark-cli`, `cc-connect`
- install `oh-my-zsh` and `powerlevel10k`
- install Meslo Nerd Font
- relink dotfiles into place
- optionally configure global Git identity
- optionally switch the default shell to `zsh`

For Yazi's `sshfs.yazi` workflow, `bootstrap.sh` also installs the platform SSHFS dependency:

- macOS: installs `macFUSE` and the official `SSHFS.pkg`
- Ubuntu/Debian: installs the `sshfs` package

After bootstrap, follow the highlighted terminal prompts from `bootstrap.sh`. Actionable follow-up items are printed with status prefixes such as `[NEXT]`, `[WARN]`, `[INFO]`, and `[DONE]`, and the command text itself is shown with ANSI emphasis in interactive terminals. Near the end of an interactive bootstrap run, the script also asks whether it should optionally auto-enable `proxy_on` for future zsh sessions; the default answer is no if that zsh helper exists.

Typical follow-up commands are `codex` or `codex login` for Codex CLI authentication, `lark-cli config init --new` and optional `lark-cli auth login` for Lark CLI setup, and `cc-connect --help` to verify the installed command. Bootstrap also runs `npx skills add larksuite/cli -g -y` for the Feishu/Lark CLI.

After changing files under `config/nvim`, verify the config before committing:

```sh
stylua --check config/nvim
nvim --headless -i NONE '+qa'
```

Private secrets should live in `~/.zsh.secrets` and should not be committed.

## Cross-platform notes

- `zsh/.zprofile` auto-detects Homebrew on macOS and Linuxbrew on Linux.
- Machine-specific overrides can go in `~/.config/zsh/local/*.zsh`.
- Private environment variables can go in `~/.zsh.secrets`.
- `bootstrap.sh` supports macOS and Ubuntu/Debian.
- On Ubuntu/Debian, `bootstrap.sh` configures NodeSource Node.js 22.x and installs `nodejs` from that source, which already provides `npm`. Do not run `apt install npm` separately.
- npm-based CLI installs in `bootstrap.sh` try `https://registry.npmmirror.com` first and fall back to `https://registry.npmjs.org` if the mirror fails.
- On macOS, `bootstrap.sh` installs `macFUSE`; the first use may still require approval in `System Settings -> Privacy & Security`.

## Tool notes

- [docs/yazi.md](/Users/hanguangjiang/dotfiles/docs/yazi.md): `yazi` launcher and common file-manager shortcuts
- [docs/shortcuts.md](/Users/hanguangjiang/dotfiles/docs/shortcuts.md): shortcut cheat sheet for Yazi, Neovim, and Tmux

## Managed links

- `~/.zshrc`
- `~/.zprofile`
- `~/.p10k.zsh`
- `~/.tmux.conf`
- `~/.config/tmux`
- `~/.config/git`
- `~/.config/nvim`
- `~/.config/yazi`
