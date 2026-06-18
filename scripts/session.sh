#!/usr/bin/env bash

if [ "${NOTIV_SCRIPT_SESSION_SOURCED:-0}" = "1" ]; then
	return 0 2>/dev/null || exit 0
fi
NOTIV_SCRIPT_SESSION_SOURCED=1

# shellcheck source=../lib/core.sh
. "$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/lib/core.sh"

notiv_session_exists() {
	local context_name session_name
	context_name="$1"
	session_name="$(notiv_session_name "$context_name")"
	tmux_cmd has-session -t "$session_name" >/dev/null 2>&1
}

notiv_session_create() {
	local context_name dir cmd session_name
	context_name="$1"
	dir="$2"
	cmd="$3"
	session_name="$(notiv_session_name "$context_name")"

	tmux_cmd new-session -d -s "$session_name" -c "$dir" "$cmd" >/dev/null
}

notiv_session_ensure() {
	local context_name dir cmd
	context_name="$1"
	dir="$2"
	cmd="$3"

	if notiv_session_exists "$context_name"; then
		printf '%s\n' "$(notiv_session_name "$context_name")"
		return 0
	fi

	notiv_session_create "$context_name" "$dir" "$cmd"
	printf '%s\n' "$(notiv_session_name "$context_name")"
}

notiv_session_main() {
	local subcommand context_name dir cmd
	subcommand="${1:-}"

	case "$subcommand" in
		exists)
			context_name="${2:-}"
			[ -n "$context_name" ] || notiv_die "session exists requires a context name"
			notiv_session_exists "$context_name"
			;;
		ensure)
			context_name="${2:-}"
			dir="${3:-}"
			cmd="${4:-}"
			[ -n "$context_name" ] || notiv_die "session ensure requires a context name"
			[ -n "$dir" ] || notiv_die "session ensure requires a directory"
			[ -n "$cmd" ] || notiv_die "session ensure requires a command"
			notiv_session_ensure "$context_name" "$dir" "$cmd"
			;;
		*)
			notiv_die "unknown session command: $subcommand"
			;;
	esac
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
	set -euo pipefail
	notiv_session_main "$@"
fi
