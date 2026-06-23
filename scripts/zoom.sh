#!/usr/bin/env bash

if [ "${NOTIV_SCRIPT_ZOOM_SOURCED:-0}" = "1" ]; then
	return 0 2>/dev/null || exit 0
fi
NOTIV_SCRIPT_ZOOM_SOURCED=1

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
export NOTIV_ROOT="${NOTIV_ROOT:-$ROOT_DIR}"

# shellcheck source=../lib/popup.sh
. "$ROOT_DIR/lib/popup.sh"

notiv_zoom_resize() {
	local step=$1
	local current_width current_height new_width new_height
	local client origin_session origin_width origin_height

	current_width=$(tmux_cmd display-message -p '#{window_width}')
	current_height=$(tmux_cmd display-message -p '#{window_height}')

	new_width=$((current_width + step))
	new_height=$((current_height + step))

	if [ "$new_width" -le 0 ] || [ "$new_height" -le 0 ]; then
		return 0
	fi

	client="$(notiv_popup_current_client 2>/dev/null || true)"
	origin_session="$(notiv_state_get_origin_session "$client")"
	if [ -n "$origin_session" ]; then
		origin_width=$(tmux_cmd display-message -p -t "$origin_session" '#{window_width}' 2>/dev/null || true)
		origin_height=$(tmux_cmd display-message -p -t "$origin_session" '#{window_height}' 2>/dev/null || true)
		if [ -n "$origin_width" ] && [ "$new_width" -gt "$origin_width" ]; then
			return 0
		fi
		if [ -n "$origin_height" ] && [ "$new_height" -gt "$origin_height" ]; then
			return 0
		fi
	fi

	notiv_env_set NOTIV_WIDTH "$new_width"
	notiv_env_set NOTIV_HEIGHT "$new_height"
	tmux_cmd detach-client >/dev/null
	notiv_popup_reopen
}

notiv_zoom_fullscreen() {
	notiv_env_set NOTIV_WIDTH "100%"
	notiv_env_set NOTIV_HEIGHT "100%"
	tmux_cmd detach-client >/dev/null
	notiv_popup_reopen
}

notiv_zoom_reset() {
	notiv_env_clear_width_height
	tmux_cmd detach-client >/dev/null
	notiv_popup_reopen
}

notiv_zoom_lock() {
	local context_name
	context_name="$(notiv_state_get_last_context)"
	notiv_set_option "@notiv_bindings_locked" "true"
	notiv_popup_lock_root_bindings
	notiv_env_set NOTIV_TITLE_OVERRIDE "$(notiv_popup_locked_title "$context_name")"
	tmux_cmd detach-client >/dev/null
	notiv_popup_reopen
}

notiv_zoom_unlock() {
	notiv_set_option "@notiv_bindings_locked" "false"
	notiv_popup_unlock_root_bindings
	notiv_env_clear NOTIV_TITLE_OVERRIDE
	tmux_cmd detach-client >/dev/null
	notiv_popup_reopen
}

notiv_zoom_main() {
	local subcommand
	subcommand="${1:-}"

	case "$subcommand" in
		in)
			notiv_zoom_resize -5
			;;
		out)
			notiv_zoom_resize 5
			;;
		full)
			notiv_zoom_fullscreen
			;;
		reset)
			notiv_zoom_reset
			;;
		lock)
			notiv_zoom_lock
			;;
		unlock)
			notiv_zoom_unlock
			;;
		*)
			notiv_die "unknown zoom command: $subcommand"
			;;
	esac
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
	set -euo pipefail
	notiv_zoom_main "$@"
fi
