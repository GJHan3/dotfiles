# Yazi Notes

This repository installs `yazi` and exposes a `y` shell wrapper from `zsh/.zshrc`.

Use `y` instead of `yazi` when you want the shell to follow the last directory you visited after quitting.

```sh
y
y .
y ~/Downloads
```

## Navigation

- `j` / `k`: move cursor down or up
- `h`: go to parent directory
- `l`: enter directory or open file
- `g`: jump to the top
- `G`: jump to the bottom
- `q`: quit

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

- `bootstrap.sh` installs `yazi` on macOS and Ubuntu/Debian.
- `yazi --version` checks whether the binary is available.
