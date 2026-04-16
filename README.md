# dotfiles

This repository stores personal shell and editor configuration for this machine.

## Layout

- `zsh/`: zsh and Powerlevel10k config
- `tmux/.tmux.conf`: tmux settings
- `config/git/ignore`: global git ignores
- `config/nvim/`: Neovim config
- `config/wezterm/wezterm.lua`: WezTerm config
- `config/yazi/`: Yazi file manager config
- `bin/claude`: Claude Code wrapper that sends version checks to native Claude
  and normal sessions through EPT
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
  `stylua`, `yazi`, `sshfs`, `node`, `codex`, `opencode`, `cc-connect`,
  `lark-cli`, and `whiteboard-cli`
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
for Lark CLI setup, `whiteboard-cli --help` to verify the whiteboard renderer,
`cc-connect --help` to verify the installed command, and `proxy_on` if you want
to enable the local proxy manually. Proxy is off by default. Bootstrap also
runs `npx skills add larksuite/cli -g -y` for the Feishu/Lark CLI.

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
- `~/.config/zsh/ept.zsh` is the shared EPT/Claude wrapper policy. It keeps
  `~/.ept/bin` ahead of npm-global Claude installs and clears `CLAUDE_PATH`.
- `~/bin/claude` is linked from `bin/claude`. It routes `--version`/`-v` directly
  to native Claude Code and routes normal sessions through `~/.ept/bin/ept`.
  Set `CLAUDE_NATIVE_PATH` on machines where Claude lives in a different path.
- Machine-specific overrides can go in `~/.config/zsh/local/*.zsh`.
- Private environment variables can go in `~/.zsh.secrets`.
- `bootstrap.sh` supports macOS and Ubuntu/Debian.
- On Ubuntu/Debian, `bootstrap.sh` configures NodeSource Node.js 22.x and
  installs `nodejs` from that source, which already provides `npm`. Do not run
  `apt install npm` separately. If NodeSource setup fails, bootstrap warns and
  falls back to the distro `nodejs` package for the rest of the run.
- `bootstrap.sh` sets the user npm registry to `https://registry.npmmirror.com`
  when npm is still using the official default registry. npm-based CLI installs
  still fall back to `https://registry.npmjs.org` if the mirror fails or if a
  command health check such as `codex --version` fails after installation.
  Global npm packages are installed under `~/.npm-global` to avoid sudo-owned
  `/usr/local` installs and missing optional native dependency problems.
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

- [docs/machine-specific.md](docs/machine-specific.md): machine-specific
  zsh configuration (local aliases, paths, per-machine overrides)
- [docs/claude-ept-cc-connect.md](docs/claude-ept-cc-connect.md): notes on
  safe Claude/EPT wrappers for `cc-connect` and npm cache recursion recovery
- [config/nvim/README.md](config/nvim/README.md): Neovim config layout and
  maintenance rules
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
- `~/.config/zsh/path.zsh`
- `~/.config/zsh/ept.zsh`
- `~/bin/claude`
- `~/.tmux.conf`
- `~/.config/tmux`
- `~/.config/git`
- `~/.config/nvim`
- `~/.config/yazi`
