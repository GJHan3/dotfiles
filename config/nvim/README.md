# Neovim Config

This directory contains the repository's LazyVim-based Neovim setup.

Layout:

- `init.lua`: Neovim entrypoint
- `lua/config/`: shared options, keymaps, autocmds, and Lazy bootstrap
- `lua/config/autocmds.lua`: index file for autocmd modules
- `lua/config/autocmds/`: focused autocmd modules
  - `ui.lua`: highlight rules and winbar setup
  - `input.lua`: macOS `im-select` input-method behavior
  - `buffers.lua`: external file reload and buffer cleanup behavior
  - `windows.lua`: special-window, Trouble, gitsigns, and terminal-window behavior
- `lua/plugins/`: plugin specs and plugin-specific overrides
- `lua/utils/`: shared helper modules used by config and plugin specs
- `stylua.toml`: formatting rules for Lua files in this directory

Organization rules:

- Keep `lua/config/autocmds.lua` as a small index. Add new autocmd behavior to the focused module that owns it, or create a new module under `lua/config/autocmds/` when the behavior is a separate concern.
- Keep direct key mappings in `lua/config/keymaps.lua`. Buffer-local mappings that are created by an event should live with the owning autocmd module.
- Keep plugin spec files in `lua/plugins/` small. If a plugin needs large component tables or helper functions, move that logic to `lua/utils/` and require it from the plugin spec.
- Do not duplicate LazyVim plugin specs or define the same behavior in both `lua/config/` and `lua/plugins/`; prefer one owner and document the behavior in `docs/shortcuts.md` when it affects user-facing keys or workflows.

When changing files under `config/nvim`, verify the result before committing:

```sh
stylua --check config/nvim
nvim --headless -i NONE '+qa'
```

`stylua` should pass without diffs, and the headless Neovim startup should exit cleanly.
