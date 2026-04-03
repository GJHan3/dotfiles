#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "xqallow only supports macOS with XQuartz" >&2
  exit 1
fi

XHOST_BIN=/usr/X11/bin/xhost
DISPLAY_VALUE=${DISPLAY:-:0}

if [[ ! -x "$XHOST_BIN" ]]; then
  echo "xhost not found at $XHOST_BIN" >&2
  echo "Install XQuartz first." >&2
  exit 1
fi

if ! pgrep -x XQuartz >/dev/null 2>&1; then
  open -a XQuartz
  sleep 3
fi

export DISPLAY="$DISPLAY_VALUE"
"$XHOST_BIN" +localhost
