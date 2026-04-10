# Yazi Notes

This repository installs `yazi` and exposes a `y` shell wrapper from `zsh/.zshrc`.

Use `y` instead of `yazi` when you want the shell to follow the last directory
you visited after quitting.

```sh
y
y .
y ~/Downloads
```

Current layout preference in this repository:

- `[mgr].ratio = [1, 2, 5]`
- This makes the preview pane wider than the current file list pane.
- `theme.toml` uses the official `catppuccin-macchiato` flavor instead of the
  stock colors.
- Files are opened with `nvim` via a custom `edit` opener.
- `*.html` and `*.htm` are opened in the system browser first, with `nvim` as a
  fallback opener.
- `sshfs.yazi` is enabled. Press `M s` to open the SSHFS menu and mount hosts
  from `~/.ssh/config`.

## Navigation

- `j` / `k`: move cursor down or up
- `h`: go to parent directory
- `l`: enter directory, or open files with the configured opener (`nvim` by
  default, browser first for `html` / `htm`)
- `g`: jump to the top
- `G`: jump to the bottom
- `g` `b`: open the hovered file in the system browser
- `M` `s`: open the SSHFS menu
- `M` `m`: mount a host and jump to it
- `M` `j`: jump to an existing mount
- `M` `u`: unmount a mounted host
- `q`: quit

## SSHFS

- `M` `s`: open the `sshfs.yazi` menu
- `M` `m`: mount a host and jump to it
- `M` `u`: unmount a mounted host
- `M` `j`: jump to an existing mount
- `M` `h`: jump to the SSHFS mount home directory
- `M` `c`: open `~/.ssh/config`
- The `M s` menu remains available if you prefer a single entry point.
- The plugin reads hosts from `~/.ssh/config` and can also keep Yazi-only custom
  hosts.
- `bootstrap.sh` installs the required SSHFS dependency on both macOS and
  Ubuntu/Debian.
- On macOS, the first mount may still require approval in `System Settings ->
  Privacy & Security` if macFUSE is blocked by the system.

## Selection

- `Space`: toggle selection for current file
- `v`: enter visual selection mode
- `Esc`: clear current selection or leave visual mode

## File operations

- `x`: cut selected files
- `y`: copy selected files
- `p`: paste into current directory
- `r`: rename current file
- `d`: move selected files to trash or delete them, depending on system support

Typical move workflow:

1. Select one or more files with `Space`.
2. Press `x`.
3. Navigate to the target directory.
4. Press `p`.

## Search

- `/`: search within current directory listing
- `n`: jump to next match
- `N`: jump to previous match

## Notes

- `bootstrap.sh` installs `yazi` and the SSHFS dependency on macOS and
  Ubuntu/Debian.
- `install.sh` runs `ya pkg install` when `ya` is available, so Yazi plugins and
  flavors are deployed after linking.
- `yazi --version` checks whether the binary is available.
