#!/usr/bin/env bash

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BOOTSTRAP_ENTRY="${REPO_DIR}/bootstrap.sh"
TEST_TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-bootstrap-test.XXXXXX")"

cleanup() {
  rm -rf "$TEST_TMP_DIR"
}
trap cleanup EXIT

fail() {
  echo "bootstrap smoke test failed: $*" >&2
  exit 1
}

assert_contains() {
  local file=$1 pattern=$2
  grep -Eq "$pattern" "$file" || fail "${file} does not contain ${pattern}"
}

assert_not_contains() {
  local file=$1 pattern=$2
  if grep -Eq "$pattern" "$file"; then
    fail "${file} unexpectedly contains ${pattern}"
  fi
}

/bin/bash -n \
  "$BOOTSTRAP_ENTRY" \
  "${REPO_DIR}"/bootstrap/lib/*.sh \
  "${REPO_DIR}"/bootstrap/installers/*.sh \
  "${REPO_DIR}"/bootstrap/custom/*.sh \
  "${REPO_DIR}"/bootstrap/platforms/*.sh \
  "${REPO_DIR}/bootstrap/workflow.sh"

"$BOOTSTRAP_ENTRY" --list > "${TEST_TMP_DIR}/list.txt"
assert_contains "${TEST_TMP_DIR}/list.txt" '^codex[[:space:]]+npm[[:space:]]+all'

BOOTSTRAP_OS_OVERRIDE=macos "$BOOTSTRAP_ENTRY" --dry-run --only codex > "${TEST_TMP_DIR}/macos-codex.txt"
assert_contains "${TEST_TMP_DIR}/macos-codex.txt" 'node[[:space:]]+brew[[:space:]]+node'
assert_contains "${TEST_TMP_DIR}/macos-codex.txt" 'npm[[:space:]]+npm[[:space:]]+npm@latest'
assert_contains "${TEST_TMP_DIR}/macos-codex.txt" 'codex[[:space:]]+npm[[:space:]]+@openai/codex@latest'
assert_not_contains "${TEST_TMP_DIR}/macos-codex.txt" 'nodesource-current'

BOOTSTRAP_OS_OVERRIDE=ubuntu "$BOOTSTRAP_ENTRY" --dry-run --only codex > "${TEST_TMP_DIR}/ubuntu-codex.txt"
assert_contains "${TEST_TMP_DIR}/ubuntu-codex.txt" 'node[[:space:]]+custom[[:space:]]+nodesource-current'
assert_contains "${TEST_TMP_DIR}/ubuntu-codex.txt" 'npm[[:space:]]+npm[[:space:]]+npm@latest'
assert_not_contains "${TEST_TMP_DIR}/ubuntu-codex.txt" 'node[[:space:]]+brew'

BOOTSTRAP_OS_OVERRIDE=macos "$BOOTSTRAP_ENTRY" --dry-run --only sshfs > "${TEST_TMP_DIR}/macos-sshfs.txt"
for dependency in glib meson ninja pkgconf; do
  assert_contains "${TEST_TMP_DIR}/macos-sshfs.txt" "${dependency}[[:space:]]+brew"
done
assert_contains "${TEST_TMP_DIR}/macos-sshfs.txt" 'sshfs[[:space:]]+custom[[:space:]]+github-release'

BOOTSTRAP_OS_OVERRIDE=ubuntu "$BOOTSTRAP_ENTRY" --dry-run --only codex --skip node > "${TEST_TMP_DIR}/skip-node.txt"
assert_not_contains "${TEST_TMP_DIR}/skip-node.txt" 'node[[:space:]]+(brew|custom)'

if "$BOOTSTRAP_ENTRY" --dry-run --only not-a-managed-tool > /dev/null 2>&1; then
  fail "unknown tool selection was accepted"
fi
if BOOTSTRAP_OS_OVERRIDE=ubuntu "$BOOTSTRAP_ENTRY" --only git > /dev/null 2>&1; then
  fail "OS override was accepted outside dry-run mode"
fi

cat > "${TEST_TMP_DIR}/node-index.json" <<'EOF'
[
{"version":"v30.2.1","date":"2030-01-01"},
{"version":"v29.9.0","date":"2029-12-01"}
]
EOF

BOOTSTRAP_SOURCE_ONLY=1 . "$BOOTSTRAP_ENTRY"
NODE_TARGET_MAJOR=""
NODE_RELEASE_INDEX="file://${TEST_TMP_DIR}/node-index.json"
resolve_node_target_major
[[ "$NODE_TARGET_MAJOR" == 30 ]] || fail "latest Node.js major parser returned ${NODE_TARGET_MAJOR}"

sudo() {
  printf '%s\n' "$*" >> "${TEST_TMP_DIR}/sudo-calls.txt"
}
SUDO_SESSION_STARTED=0
SUDO_KEEPALIVE_PID=""
SUDO_KEEPALIVE_INTERVAL_SECONDS=1
ensure_sudo_session > /dev/null
ensure_sudo_session > /dev/null
[[ $SUDO_SESSION_STARTED -eq 1 ]] || fail "sudo session did not start"
[[ "$(grep -c '^-v$' "${TEST_TMP_DIR}/sudo-calls.txt")" -eq 1 ]] || fail "sudo authenticated more than once"
stop_sudo_session
[[ $SUDO_SESSION_STARTED -eq 0 ]] || fail "sudo session did not stop"
assert_contains "${TEST_TMP_DIR}/sudo-calls.txt" '^-k$'
unset -f sudo

INSTALL_FAILURE_COUNT=0
INSTALL_FAILURE_MESSAGES=()
run_optional_step "expected failure" false
[[ $INSTALL_FAILURE_COUNT -eq 1 ]] || fail "optional failure was not recorded"
if print_bootstrap_result > /dev/null; then
  fail "failure summary returned success"
fi

clone_or_update_repo() {
  [[ "$1" != https://github.com/ohmyzsh/ohmyzsh.git ]]
}
ONLY_TOOLS=shell-framework
SKIP_TOOLS=""
if install_shell_framework; then
  fail "shell framework installer masked a repository failure"
fi

original_tools_manifest=$TOOLS_MANIFEST
printf '%s\n' 'broken|npm|package|command|--version|all|Missing fallback column' > "${TEST_TMP_DIR}/invalid-tools.tsv"
TOOLS_MANIFEST="${TEST_TMP_DIR}/invalid-tools.tsv"
if validate_manifests > /dev/null 2>&1; then
  fail "invalid manifest field count was accepted"
fi
TOOLS_MANIFEST=$original_tools_manifest

echo "bootstrap smoke tests passed"
