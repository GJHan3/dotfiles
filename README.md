# dotfiles

This repository stores personal shell and editor configuration for this machine.

## Layout

- `zsh/`: zsh and Powerlevel10k config
- `tmux/.tmux.conf`: tmux settings
- `config/git/ignore`: global git ignores
- `config/nvim/`: Neovim config
- `config/wezterm/wezterm.lua`: WezTerm config
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

By default, `bootstrap.sh` skips tools that are already installed. Use `--force`
to reinstall or refresh managed tools:

```sh
~/dotfiles/bootstrap.sh --force
```

`bootstrap.sh` can:

- install `git`, `zsh`, `tmux`, `neovim`, `ripgrep`, `fd`, `fzf`, `lazygit`,
  `stylua`, `yazi`, `sshfs`, `node`, `codex`, `lark-cli`, `cc-connect`
- install `oh-my-zsh` and `powerlevel10k`
- install Meslo Nerd Font
- relink dotfiles into place
- optionally configure global Git identity
- optionally switch the default shell to `zsh`

For Yazi's `sshfs.yazi` workflow, `bootstrap.sh` also installs the platform SSHFS
dependency:

- macOS: installs `macFUSE` and the official `SSHFS.pkg`
- Ubuntu/Debian: installs the `sshfs` package

After bootstrap, follow the highlighted terminal prompts from `bootstrap.sh`.
Actionable follow-up items are printed with status prefixes such as `[NEXT]`,
`[WARN]`, `[INFO]`, and `[DONE]`, and the command text itself is shown with ANSI
emphasis in interactive terminals. If npm-based CLI tools such as `codex`,
`lark-cli`, or `cc-connect` are still missing after bootstrap, the script now
prints a `[WARN]` block so the missing command is obvious.

Typical follow-up commands are `codex` or `codex login` for Codex CLI
authentication, `lark-cli config init --new` and optional `lark-cli auth login`
for Lark CLI setup, `cc-connect --help` to verify the installed command, and
`proxy_on` if you want to enable the local proxy manually. Proxy is off by
default. Bootstrap also runs `npx skills add larksuite/cli -g -y` for the
Feishu/Lark CLI.

After changing files under `config/nvim`, verify the config before committing:

```sh
stylua --check config/nvim
nvim --headless -i NONE '+qa'
```

Private secrets should live in `~/.zsh.secrets` and should not be committed.

## Cross-platform notes

- `~/.config/zsh/path.zsh` is the shared PATH policy for both login and
  interactive `zsh`. It auto-detects Homebrew/Linuxbrew and adds common
  user-level tool bins such as `~/.local/bin`, npm global bin, `pnpm`, `cargo`,
  `go`, and `bun`.
- Machine-specific overrides can go in `~/.config/zsh/local/*.zsh`.
- Private environment variables can go in `~/.zsh.secrets`.
- `bootstrap.sh` supports macOS and Ubuntu/Debian.
- On Ubuntu/Debian, `bootstrap.sh` configures NodeSource Node.js 22.x and
  installs `nodejs` from that source, which already provides `npm`. Do not run
  `apt install npm` separately.
- npm-based CLI installs in `bootstrap.sh` try `https://registry.npmmirror.com`
  first and fall back to `https://registry.npmjs.org` if the mirror fails.
- On macOS, `bootstrap.sh` installs `macFUSE`; the first use may still require
  approval in `System Settings -> Privacy & Security`.
- On macOS, if you want remote X11 forwarding such as `ssh -Y`, `sshx11`, or
  clipboard/image workflows that depend on an X server, install and launch
  `XQuartz` first. See [docs/x11-xquartz-codex.md](docs/x11-xquartz-codex.md)
  for the full setup and troubleshooting flow.
- `install.sh` and `bootstrap.sh` now also bridge `~/.codex-home/.Xauthority` to
  `~/.Xauthority`, and `zsh/.zshrc` auto-exports `XAUTHORITY` from the real user
  home when `DISPLAY` is present. This avoids common X11 auth failures for CLIs
  that run with an isolated `HOME`.

## Tool notes

- [docs/yazi.md](docs/yazi.md): `yazi` launcher and
  common file-manager shortcuts
- [docs/shortcuts.md](docs/shortcuts.md): shortcut
  cheat sheet for Yazi, Neovim, and Tmux
- `scripts/check-osc52.sh`: emit a one-time OSC 52 clipboard token for quick
  terminal/tmux verification

## Managed links

- `~/.zshrc`
- `~/.zprofile`
- `~/.p10k.zsh`
- `~/.wezterm.lua`
- `~/.tmux.conf`
- `~/.config/tmux`
- `~/.config/git`
- `~/.config/nvim`
- `~/.config/yazi`
