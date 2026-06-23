#!/usr/bin/env bash

if [ "${NOTIV_SCRIPT_SESSION_SOURCED:-0}" = "1" ]; then
	return 0 2>/dev/null || exit 0
fi
NOTIV_SCRIPT_SESSION_SOURCED=1

# shellcheck source=./config.sh
. "$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/config.sh"

notiv_session_name() {
	notiv_config_session_name
}

notiv_session_exists() {
	tmux_cmd has-session -t "$(notiv_session_name)" >/dev/null 2>&1
}

notiv_window_target() {
	local context_name
	context_name="$1"
	printf '%s:%s\n' "$(notiv_session_name)" "$(notiv_window_name "$context_name")"
}

notiv_window_exists() {
	local context_name session_name window_name
	context_name="$1"
	session_name="$(notiv_session_name)"
	window_name="$(notiv_window_name "$context_name")"

	if ! notiv_session_exists; then
		return 1
	fi

	tmux_cmd list-windows -t "$session_name" -F '#{window_name}' 2>/dev/null | while IFS= read -r current_window_name; do
		if [ "$current_window_name" = "$window_name" ]; then
			return 0
		fi
	done
}

notiv_session_window_count() {
	local session_name
	session_name="$(notiv_session_name)"

	if ! notiv_session_exists; then
		printf '0\n'
		return 0
	fi

	tmux_cmd list-windows -t "$session_name" 2>/dev/null | wc -l | tr -d ' '
}

notiv_window_matches_configuration() {
	local context_name dir cmd
	context_name="$1"
	dir="$2"
	cmd="$3"

	[ "$(notiv_state_get_context_dir "$context_name")" = "$dir" ] &&
		[ "$(notiv_state_get_context_cmd "$context_name")" = "$cmd" ]
}

notiv_window_track_configuration() {
	local context_name dir cmd
	context_name="$1"
	dir="$2"
	cmd="$3"

	notiv_state_set_context_dir "$context_name" "$dir"
	notiv_state_set_context_cmd "$context_name" "$cmd"
}

notiv_window_clear_configuration() {
	local context_name
	context_name="$1"

	notiv_state_clear_context_dir "$context_name"
	notiv_state_clear_context_cmd "$context_name"
}

notiv_window_create() {
	local context_name dir cmd session_name window_name
	context_name="$1"
	dir="$2"
	cmd="$3"
	session_name="$(notiv_session_name)"
	window_name="$(notiv_window_name "$context_name")"

	if notiv_session_exists; then
		tmux_cmd new-window -d -t "$session_name" -n "$window_name" -c "$dir" "$cmd" >/dev/null
	else
		tmux_cmd new-session -d -s "$session_name" -n "$window_name" -c "$dir" "$cmd" >/dev/null
	fi

	notiv_window_track_configuration "$context_name" "$dir" "$cmd"
}

notiv_window_recreate() {
	local context_name dir cmd
	context_name="$1"
	dir="$2"
	cmd="$3"

	tmux_cmd kill-window -t "$(notiv_window_target "$context_name")" >/dev/null
	notiv_window_clear_configuration "$context_name"
	notiv_window_create "$context_name" "$dir" "$cmd"
}

notiv_session_ensure() {
	local context_name dir cmd
	context_name="$1"
	dir="$2"
	cmd="$3"

	if notiv_window_exists "$context_name"; then
		if [ "$(notiv_config_change_path)" = "true" ]; then
			if ! notiv_window_matches_configuration "$context_name" "$dir" "$cmd"; then
				notiv_window_recreate "$context_name" "$dir" "$cmd"
			fi
		fi
	else
		notiv_window_create "$context_name" "$dir" "$cmd"
	fi

	printf '%s\n' "$(notiv_window_target "$context_name")"
}

notiv_session_main() {
	local subcommand context_name dir cmd
	subcommand="${1:-}"

	case "$subcommand" in
		exists)
			context_name="${2:-}"
			[ -n "$context_name" ] || notiv_die "session exists requires a context name"
			notiv_window_exists "$context_name"
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
