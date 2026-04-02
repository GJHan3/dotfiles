# Neovim Config

This directory contains the repository's LazyVim-based Neovim setup.

Layout:

- `init.lua`: Neovim entrypoint
- `lua/config/`: shared options, keymaps, autocmds, and Lazy bootstrap
- `lua/plugins/`: plugin specs and plugin-specific overrides
- `stylua.toml`: formatting rules for Lua files in this directory

When changing files under `config/nvim`, verify the result before committing:

```sh
stylua --check config/nvim
nvim --headless -i NONE '+qa'
```

`stylua` should pass without diffs, and the headless Neovim startup should exit cleanly.
