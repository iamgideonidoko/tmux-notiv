#!/usr/bin/env bash

if [ "${NOTIV_SCRIPT_EMBED_SOURCED:-0}" = "1" ]; then
	return 0 2>/dev/null || exit 0
fi
NOTIV_SCRIPT_EMBED_SOURCED=1

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
export NOTIV_ROOT="${NOTIV_ROOT:-$ROOT_DIR}"

# shellcheck source=../lib/popup.sh
. "$ROOT_DIR/lib/popup.sh"

notiv_embed_embed() {
	local client origin_session notiv_session window_count

	notiv_set_option "@notiv_bindings_locked" "false"
	notiv_env_clear NOTIV_TITLE_OVERRIDE
	notiv_popup_unset_root_bindings

	client="$(notiv_popup_current_client 2>/dev/null || true)"
	origin_session="$(notiv_state_get_origin_session "$client")"
	notiv_session="$(notiv_session_name)"

	[ -n "$origin_session" ] || notiv_die "unable to determine origin session for embed"

	window_count="$(notiv_session_window_count)"
	if [ "$window_count" -le 1 ]; then
		tmux_cmd new-window -d -t "$notiv_session" >/dev/null 2>&1 || true
	fi

	tmux_cmd movew -t "$origin_session" >/dev/null
	tmux_cmd detach-client >/dev/null
}

notiv_embed_pop() {
	local client origin_session notiv_session

	client="$(notiv_popup_current_client 2>/dev/null || true)"
	origin_session="$(notiv_state_get_origin_session "$client")"
	[ -n "$origin_session" ] || origin_session="$(notiv_popup_current_session 2>/dev/null || true)"
	notiv_session="$(notiv_session_name)"

	if ! notiv_session_exists; then
		tmux_cmd new-session -d -s "$notiv_session" >/dev/null 2>&1
		tmux_cmd set-option -t "$notiv_session" status off >/dev/null 2>&1 || true
	fi

	tmux_cmd movew -t "$notiv_session" >/dev/null

	if [ -n "$client" ] && [ -n "$origin_session" ]; then
		notiv_state_set_origin_session "$client" "$origin_session"
	fi

	notiv_popup_reopen
}

notiv_embed_main() {
	local subcommand
	subcommand="${1:-embed}"

	case "$subcommand" in
		embed)
			notiv_embed_embed
			;;
		pop)
			notiv_embed_pop
			;;
		*)
			notiv_die "unknown embed command: $subcommand"
			;;
	esac
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
	set -euo pipefail
	notiv_embed_main "$@"
fi
