# Machine-specific configuration

Some settings only make sense on a particular machine — local tool paths, machine-specific
aliases, proxy addresses, etc. These should **not** be committed to the dotfiles repo.

## How it works

`zsh/.zshrc` automatically sources every `*.zsh` file found in `~/.config/zsh/local/`:

```zsh
if [[ -d "$HOME/.config/zsh/local" ]]; then
  for local_rc in "$HOME/.config/zsh/local"/*.zsh(N); do
    source "$local_rc"
  done
fi
```

`install.sh` creates this directory during setup. The directory itself is not tracked by git.

## Adding config for the current machine

```sh
# Create a file named after the machine (keeps things obvious)
touch ~/.config/zsh/local/$(hostname).zsh

# Edit it
nvim ~/.config/zsh/local/$(hostname).zsh
```

Example contents:

```zsh
# ~/.config/zsh/local/LX-MBA.zsh

export PATH="/Users/hanguangjiang/.ept/bin:$PATH"
alias claude="ept claude"
alias codex="ept codex"
alias opencode="ept opencode"
```

Reload without restarting the shell:

```sh
source ~/.zshrc
```

## Tips

- You can split config into multiple files, e.g. `aliases.zsh`, `env.zsh`, `proxy.zsh`.
  All `*.zsh` files in the directory are sourced in glob order.
- For **private credentials** (API keys, tokens) use `~/.zsh.secrets` instead — same
  mechanism, dedicated file. See `.zsh.secrets.example` in the repo for a template.
- The common/shared zsh config lives in `dotfiles/zsh/.zshrc` (symlinked to `~/.zshrc`)
  and `dotfiles/config/zsh/path.zsh` (PATH management). Edit those for changes that
  should apply to every machine.
