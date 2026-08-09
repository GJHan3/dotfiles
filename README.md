# dotfiles

This repository stores personal shell and editor configuration for this machine.

## Layout

- `zsh/`: zsh and Powerlevel10k config
- `tmux/.tmux.conf`: tmux settings
- `config/git/ignore`: global git ignores
- `config/nvim/`: Neovim config
- `config/wezterm/wezterm.lua`: WezTerm config
- `config/yazi/`: Yazi file manager config
- `bin/clipimg`: clipboard image saver for macOS, Wayland, and X11
- `bin/claude`: Claude Code wrapper that sends version checks to native Claude
  and normal sessions through EPT
- `bootstrap.sh`: stable entry point for installing and updating managed tools
- `bootstrap/tools.tsv`: declarative software manifest shared by both platforms
- `bootstrap/dependencies.tsv`: dependency expansion used by targeted installs
- `bootstrap/lib/`: argument parsing, selection, status output, and manifest helpers
- `bootstrap/platforms/`: Homebrew and Ubuntu/Debian package-manager adapters
- `bootstrap/installers/` and `bootstrap/custom/`: npm installer and special hooks
- `bootstrap/tests/smoke.sh`: side-effect-free architecture and platform-plan tests
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

To refresh managed tools without relinking dotfiles or touching user config
steps, run:

```sh
~/dotfiles/bootstrap.sh --update
```

This update mode reuses the normal tool install flow with refresh behavior, then
exits before `install.sh` can replace any existing `~/.config` data.
On macOS, it upgrades outdated managed Homebrew formulae instead of asking
Homebrew to reinstall formulae that are already current. Node.js is also upgraded
when its unversioned Homebrew formula is outdated, because npm-based tools depend
on a supported runtime. npm CLIs are installed from the official registry first,
verified from `~/.npm-global/bin`, and then exposed ahead of older global installs.
For npm 12+, lifecycle scripts are permitted only for the exact manifest package
being installed; bootstrap does not enable arbitrary global install scripts.

The bootstrap entry point also supports inspecting and narrowing the manifest:

```sh
./bootstrap.sh --list
./bootstrap.sh --dry-run
./bootstrap.sh --only node,npm,codex
./bootstrap.sh --update --skip tailscale,sshfs
BOOTSTRAP_OS_OVERRIDE=ubuntu ./bootstrap.sh --dry-run
```

`--only` accepts manifest names, automatically includes Node.js and npm for an
npm CLI, and implies `--update --force`. `--skip` always wins over an implicit
dependency. `BOOTSTRAP_OS_OVERRIDE` is accepted only in dry-run mode, so the
other platform's plan can be checked without changing the host system.

Independent tool failures are collected instead of stopping later installers.
The final summary returns a non-zero status and lists failed tool names; `[DONE]`
is printed only when every selected installer completed successfully.

`bootstrap.sh` can:

- install `git`, `zsh`, `tmux`, `neovim`, `ripgrep`, `fd`, `fzf`, `lazygit`,
  `stylua`, `yazi`, `sshfs`, `tailscale`, `node`, `codex`, `opencode`, `claude`,
  `cc-connect`, `lark-cli`, and `whiteboard-cli`
- install `oh-my-zsh` and `powerlevel10k`
- install Meslo Nerd Font
- relink dotfiles into place
- optionally configure global Git identity
- optionally switch the default shell to `zsh`

Standard Homebrew, apt, and npm software is declared in `bootstrap/tools.tsv`,
with targeted-install dependencies in `bootstrap/dependencies.tsv`.
Adding a regular package usually requires one manifest row per supported
platform; installers that need release-API discovery, repository setup, casks,
or source builds live as small hooks under `bootstrap/custom/`.

After changing the installation architecture, run:

```sh
./bootstrap/tests/smoke.sh
```

For Yazi's `sshfs.yazi` workflow, `bootstrap.sh` also installs the platform SSHFS
dependency:

- macOS: upgrades `macFUSE`, installs the newest official `SSHFS.pkg` when one is
  published, and otherwise builds the newest SSHFS release from source; the
  source build is installed under `~/.local`, and the resolved release is
  recorded under `~/.local/state/dotfiles-bootstrap/`
- Ubuntu/Debian: installs the `sshfs` package

After bootstrap, follow the highlighted terminal prompts from `bootstrap.sh`.
Actionable follow-up items are printed with status prefixes such as `[NEXT]`,
`[WARN]`, `[INFO]`, and `[DONE]`, and the command text itself is shown with ANSI
emphasis in interactive terminals. If npm-based CLI tools such as `codex`,
`lark-cli`, `opencode`, `claude`, or `cc-connect` are still missing after bootstrap, the
script now prints a `[WARN]` block so the missing command is obvious.

Typical follow-up commands are `codex` or `codex login` for Codex CLI
authentication, `lark-cli config init --new` and optional `lark-cli auth login`
for Lark CLI setup, `whiteboard-cli --help` to verify the whiteboard renderer,
`opencode` or `opencode auth login` for OpenCode, `claude` for Claude Code,
`cc-connect --help` to verify the installed command, `sudo tailscale up` on
Linux or `open -a Tailscale` on macOS to join the tailnet, `tailscale status` to
list devices, and `proxy_on` if you want to enable the local proxy manually.
Proxy is off by default. Bootstrap also installs the Feishu/Lark CLI skill with
`npx skills add larksuite/cli -g -y`.

After changing files under `config/nvim`, verify the config before committing:

```sh
stylua --check config/nvim
nvim --headless -i NONE '+qa'
```

Private secrets should live in `~/.zsh.secrets` and should not be committed.

## Tailscale usage

After bootstrap installs Tailscale, authenticate the machine before expecting
other tailnet devices to see it.

On Ubuntu/Debian, start Tailscale and sign in from the browser prompt:

```sh
sudo tailscale up
```

On macOS, open the app, sign in, and approve the VPN/network extension if macOS
asks for permission:

```sh
open -a Tailscale
```

Useful daily commands after login:

```sh
tailscale status
tailscale ip -4
sudo tailscale down
```

Use `tailscale status` to find machines in the tailnet. The first column is the
Tailscale IP, the second column is the MagicDNS machine name, and the OS column
helps identify Linux/macOS targets:

```text
100.98.107.124  yellow-pc  user@  linux  idle
```

From another device in the same tailnet, connect with the target machine's
system username and either its Tailscale IP or MagicDNS name:

```sh
ssh hanguangjiang@100.98.107.124
ssh hanguangjiang@yellow-pc
```

If ping works but SSH appears to hang, first check whether port 22 is reachable:

```sh
nc -vz 100.98.107.124 22
```

If the port is reachable, inspect the SSH handshake:

```sh
ssh -vvv hanguangjiang@100.98.107.124
```

If the port is refused or times out, fix the target Linux machine's SSH service:

```sh
sudo systemctl status ssh
sudo systemctl enable --now ssh
sudo ss -lntp | grep ':22'
```

Only configure subnet routes when you need access to the whole LAN behind this
machine, not just this machine itself.

## Cross-platform notes

- `~/.config/zsh/path.zsh` is the shared PATH policy for both login and
  interactive `zsh`. It auto-detects Homebrew/Linuxbrew and adds common
  user-level tool bins such as `~/.local/bin`, npm global bin, `pnpm`, `cargo`,
  `go`, and `bun`.
- `~/.config/zsh/ept.zsh` is the shared EPT wrapper policy. It keeps
  `~/.ept/bin` and the repo-managed Claude wrapper ahead of npm-global native installs,
  then clears stale wrapper path overrides.
- `~/bin/claude` is linked from `bin/claude`. It routes `--version`/`-v` directly
  to native Claude Code and routes normal sessions through `~/.ept/bin/ept`.
  Set `CLAUDE_NATIVE_PATH` on machines where Claude lives in a different path.
- OpenCode runs directly from the current `opencode-ai` package installed under
  `~/.npm-global`; it does not use a repo-managed wrapper.
- Machine-specific overrides can go in `~/.config/zsh/local/*.zsh`.
- Private environment variables can go in `~/.zsh.secrets`.
- `bootstrap.sh` supports macOS and Ubuntu/Debian.
- For private network access, `bootstrap.sh` installs Tailscale from the
  official stable package source: the standalone macOS package on macOS, and the
  official Tailscale apt repository on Ubuntu/Debian. It does not authenticate
  automatically; run `sudo tailscale up` on Linux, or open the Tailscale app on
  macOS, then sign in.
- On Ubuntu/Debian, `bootstrap.sh` resolves the newest current Node.js major from
  the official Node.js release index, configures that NodeSource channel, and
  installs `nodejs` from it. The package already provides `npm`; do not run
  `apt install npm` separately. If NodeSource setup fails, bootstrap warns and
  falls back to the distro `nodejs` package for the rest of the run.
- `bootstrap.sh` sets the user npm registry to `https://registry.npmmirror.com`
  when npm is still using the official default registry. Managed npm CLI updates
  use `https://registry.npmjs.org` first so `@latest` resolves authoritatively,
  then fall back to the mirror if the official registry is unavailable or a
  package health check fails.
  Bootstrap updates npm itself with `npm@latest` before installing npm-based CLI
  tools. Global npm packages are installed under `~/.npm-global` to avoid
  sudo-owned `/usr/local` installs and missing optional native dependency
  problems.
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
- `~/bin/clipimg`
- `~/.tmux.conf`
- `~/.config/tmux`
- `~/.config/git`
- `~/.config/nvim`
- `~/.config/yazi`
