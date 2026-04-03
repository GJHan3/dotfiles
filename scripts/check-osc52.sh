#!/usr/bin/env bash

set -euo pipefail

token="osc52-$(date +%s)"
base64_cmd=""

if command -v base64 >/dev/null 2>&1; then
  base64_cmd="base64"
elif command -v openssl >/dev/null 2>&1; then
  base64_cmd="openssl base64 -A"
else
  echo "[FAIL] Missing base64 encoder: need \`base64\` or \`openssl\`." >&2
  exit 1
fi

encode_base64() {
  if [[ "$base64_cmd" == "base64" ]]; then
    printf "%s" "$1" | base64 | tr -d '\r\n'
  else
    printf "%s" "$1" | openssl base64 -A | tr -d '\r\n'
  fi
}

emit_osc52() {
  local payload=$1

  if [[ -n "${TMUX:-}" ]]; then
    printf '\033Ptmux;\033\033]52;c;%s\007\033\\' "$payload"
  else
    printf '\033]52;c;%s\007' "$payload"
  fi
}

print_env() {
  local mode="direct"

  if [[ -n "${TMUX:-}" ]]; then
    mode="tmux"
  fi

  printf "[INFO] Mode: %s\n" "$mode"
  printf "[INFO] SSH_CONNECTION=%s\n" "${SSH_CONNECTION:-}"
  printf "[INFO] TERM=%s\n" "${TERM:-}"
  printf "[INFO] TERM_PROGRAM=%s\n" "${TERM_PROGRAM:-}"
  printf "[INFO] DISPLAY=%s\n" "${DISPLAY:-}"
  printf "[INFO] WAYLAND_DISPLAY=%s\n" "${WAYLAND_DISPLAY:-}"
}

main() {
  local payload
  payload="$(encode_base64 "$token")"

  print_env
  printf "[INFO] Sending OSC 52 token: %s\n" "$token"
  emit_osc52 "$payload"
  printf "\n"
  printf "[NEXT] Paste into a local text field.\n"
  printf "[NEXT] Expected value: %s\n" "$token"
  printf "[DONE] If the pasted value matches, OSC 52 is working for this session.\n"
}

main "$@"
