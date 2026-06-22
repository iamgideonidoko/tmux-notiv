#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
SOCKET="notiv-test-$$"
SESSION="notiv-integration"

cleanup() {
	tmux -L "$SOCKET" kill-server >/dev/null 2>&1 || true
}
trap cleanup EXIT

tmux -L "$SOCKET" start-server
tmux -L "$SOCKET" new-session -d -s "$SESSION" -c "$ROOT_DIR"
tmux -L "$SOCKET" set-option -gq @notiv_notes_dir "$ROOT_DIR"
tmux -L "$SOCKET" set-option -gq @notiv_default_cmd "sh"

NOTIV_TMUX_SOCKET="$SOCKET" "$ROOT_DIR/scripts/cli.sh" reload >/dev/null 2>&1 || true
NOTIV_TMUX_SOCKET="$SOCKET" bash "$ROOT_DIR/scripts/session.sh" ensure notes "$ROOT_DIR" sh >/dev/null

if ! tmux -L "$SOCKET" has-session -t "scratch-notiv" >/dev/null 2>&1; then
	printf 'notiv session missing\n' >&2
	exit 1
fi

if ! tmux -L "$SOCKET" list-windows -t "scratch-notiv" -F '#{window_name}' | grep -Fx "notes" >/dev/null 2>&1; then
	printf 'notes window missing\n' >&2
	exit 1
fi

printf 'test_integration: ok\n'
