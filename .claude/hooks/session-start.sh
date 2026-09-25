#!/bin/bash
#
# SessionStart hook for Claude Code on the web: make a fresh cloud container
# ready for the ClearHead loop (see .claude/skills/clearhead). Local sessions are
# untouched; use scripts/startup there.
#
# - checks out submodules that are not checked out yet
# - installs the versioned git hooks (the clearhead-core pre-push gate)
# - builds the CLI from this checkout and puts target/debug on PATH, so
#   `clearhead` is always the branch's own build (overnight-runbook, Setup 4)
#
# Idempotent: a resumed or compacted session re-runs it cheaply.
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

cd "${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel)}"

# Only initialize submodules that are missing. A plain `git submodule update
# --init` would also move an initialized submodule back to its pinned commit,
# detaching a branch that a resumed session is working on.
missing=$(git submodule status | sed -n 's/^-[0-9a-f]* \([^ ]*\).*/\1/p')
if [ -n "$missing" ]; then
  # shellcheck disable=SC2086 # one path per word
  git submodule update --init -- $missing
fi

sh scripts/install-hooks.sh

# Build from the platform root so .cargo/config.toml patches the grammar to the
# tree-sitter-actions submodule, as every other platform build does.
cargo build --manifest-path clearhead-core/Cargo.toml -p clearhead_cli

if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  echo "export PATH=\"$PWD/clearhead-core/target/debug:\$PATH\"" >> "$CLAUDE_ENV_FILE"
fi
