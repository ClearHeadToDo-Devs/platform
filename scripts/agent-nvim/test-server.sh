#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
tmp=$(mktemp -d)
repo="$tmp/worktree"
state="$tmp/state"
pid=''

cleanup() {
	if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
		kill "$pid" 2>/dev/null || true
	fi
	rm -rf "$tmp"
}
trap cleanup EXIT INT TERM

mkdir -p "$repo/src"
git -C "$repo" init -q
printf 'pub fn ready() -> bool { true }\n' >"$repo/src/lib.rs"

export AGENT_NVIM_ROOT="$repo"
export AGENT_NVIM_STATE_DIR="$state"
export AGENT_NVIM_INIT=NONE
export AGENT_NVIM_WAIT_LSP=0
export AGENT_NVIM_WAIT_SECONDS=5

start_output=$($script_dir/server start)
printf '%s\n' "$start_output" | grep -q '^started$'
target=$($script_dir/server target)
[ -S "$target" ]
pid=$(cat "$state"/*.pid)
kill -0 "$pid"

second_start=$($script_dir/server start)
printf '%s\n' "$second_start" | grep -q '^already running$'
status=$($script_dir/server status)
printf '%s\n' "$status" | grep -q '^running$'
printf '%s\n' "$status" | grep -Eq '^memory_mib: [0-9]+\.[0-9]$'
printf '%s\n' "$status" | grep -q '^rust_analyzer: 0$'

$script_dir/server stop >/dev/null
if kill -0 "$pid" 2>/dev/null; then
	echo "test-server: Neovim survived stop" >&2
	exit 1
fi
pid=''
if $script_dir/server status >/dev/null 2>&1; then
	echo "test-server: stopped server reported running" >&2
	exit 1
fi

printf 'agent-nvim server tests passed\n'
