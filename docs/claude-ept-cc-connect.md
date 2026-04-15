# Claude, EPT, and cc-connect Wrapper Notes

This note records the `cc-connect` + `ept claude` recursion issue seen on
2026-04-15 and the wrapper pattern that avoids it.

## Symptom

Running or starting `cc-connect` may create many short-lived processes like:

```text
ept claude --version
npm install @anthropic-ai/claude-code@...
npm cache clean
```

The npm side can then fail with cache and rename errors:

```text
EEXIST: file already exists, rename ~/.npm/_cacache/tmp/... -> ~/.npm/_cacache/content-v2/...
ENOTEMPTY: directory not empty, rmdir ~/.npm/_cacache/tmp
Remove the existing file and try again, or run npm with --force
```

This is usually not a package registry problem. It is a recursion/concurrency
problem: many processes are trying to resolve or install Claude Code at the
same time.

## Root Cause

`cc-connect` uses `type = "claudecode"` and resolves the `claude` command from
`PATH`. On this machine, `cc-connect` was started with a wrapper directory first:

```text
PATH=/home/hanguangjiang/workspace/cc-connect-bin:...
```

So `cc-connect` found:

```text
/home/hanguangjiang/workspace/cc-connect-bin/claude
```

A naive wrapper that forwards every invocation to EPT looks like:

```bash
exec /home/hanguangjiang/.ept/bin/ept claude "$@"
```

That is fine for normal Claude sessions, but unsafe for version checks.
When `cc-connect` runs `claude --version`, the wrapper turns it into:

```text
ept claude --version
```

EPT may then perform its own Claude Code version check. If native Claude's
directory is not ahead of the wrapper directory in `PATH`, that internal check
can resolve `claude` back to the same wrapper and spawn another:

```text
ept claude --version -> wrapper -> ept claude --version -> ...
```

If the native Claude package is missing or half-installed, the same loop can
also trigger repeated npm installs. Concurrent npm installs then corrupt or
fight over `~/.npm/_cacache`.

## Recommended Wrapper Pattern

Wrappers can still be used. The important rules are:

1. Find a real Claude Code executable first.
2. Send `--version` and `-v` directly to the real Claude executable, not to EPT.
3. For normal sessions, set `CLAUDE_PATH` to the real executable.
4. Prepend the real executable's directory to `PATH` before entering EPT.

The repo-managed implementation lives at `bin/claude` and is linked to
`~/bin/claude` by `install.sh`. If a machine stores native Claude in a different
location, set `CLAUDE_NATIVE_PATH` to the real executable path.

Minimal example:

```bash
#!/usr/bin/env bash
set -euo pipefail

for claude_path in \
  "$HOME/.local/share/fnm/node-versions/v20.20.1/installation/bin/claude" \
  "$HOME/.local/share/fnm/node-versions/v18.20.8/installation/bin/claude" \
  "$HOME/.npm-global/bin/claude"; do
  if [[ -x "$claude_path" ]]; then
    if [[ "${1:-}" == "--version" || "${1:-}" == "-v" ]]; then
      exec "$claude_path" "$@"
    fi

    export CLAUDE_PATH="$claude_path"
    export PATH="$(dirname "$claude_path"):$PATH"
    exec "$HOME/.ept/bin/ept" claude "$@"
  fi
done

echo "claude executable not found; install @anthropic-ai/claude-code first" >&2
exit 127
```

This lets `cc-connect` keep using a wrapper for normal Claude sessions while
making health checks and version checks deterministic and non-recursive.

## Diagnostics

Check whether recursion is happening:

```sh
pgrep -af '[e]pt claude --version|[n]pm install @anthropic-ai|[n]pm cache'
```

Check what `cc-connect` will resolve first:

```sh
tr '\0' '\n' < /proc/$(pgrep -n -f '[c]c-connect')/environ | rg '^(PATH|CLAUDE_PATH|PWD|HOME)='
```

Check the wrapper directly:

```sh
/home/hanguangjiang/workspace/cc-connect-bin/claude --version
/home/hanguangjiang/bin/claude --version
```

Both should print the native Claude Code version without creating new
`ept claude --version` processes.

## Recovery Steps

If the system is already in a bad state:

1. Stop `cc-connect` temporarily.
2. Kill lingering `ept claude --version`, `npm install @anthropic-ai/claude-code`,
   and `npm cache` processes.
3. Move broken cache/package directories aside instead of deleting them first:

```sh
mv ~/.npm/_cacache ~/.npm/_cacache.corrupt-YYYYMMDD-HHMM
mv ~/.local/share/fnm/node-versions/v20.20.1/installation/lib/node_modules/@anthropic-ai \
  ~/.cache/npm-repair-backups/anthropic-ai.corrupt-YYYYMMDD-HHMM
```

4. Reinstall native Claude Code serially.
5. Verify `claude --version`.
6. Restart `cc-connect`.

After verification, old `*.corrupt-*` backups can be removed manually.
