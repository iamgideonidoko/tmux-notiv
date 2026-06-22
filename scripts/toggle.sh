#!/usr/bin/env bash

if [ "${NOTIV_SCRIPT_TOGGLE_SOURCED:-0}" = "1" ]; then
	return 0 2>/dev/null || exit 0
fi
NOTIV_SCRIPT_TOGGLE_SOURCED=1

# shellcheck source=./registry.sh
. "$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/registry.sh"
# shellcheck source=./session.sh
. "$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/session.sh"
# shellcheck source=../lib/popup.sh
. "$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/lib/popup.sh"

notiv_open_context() {
	local context_name record dir cmd width height target target_window
	context_name="$1"
	record="$(notiv_registry_resolve "$context_name")" || notiv_die "unknown context '$context_name'"
	dir="$(notiv_record_field "$record" 2)"
	cmd="$(notiv_record_field "$record" 3)"
	width="$(notiv_record_field "$record" 4)"
	height="$(notiv_record_field "$record" 5)"

	target="$(notiv_session_ensure "$context_name" "$dir" "$cmd")"

	if notiv_popup_inside_session; then
		target_window="${target#*:}"
		if [ "$(notiv_popup_current_window 2>/dev/null || true)" != "$target_window" ]; then
			notiv_popup_switch_context "$context_name" "$target"
		fi
		return 0
	fi

	notiv_popup_open "$context_name" "$dir" "$target" "$width" "$height"
}

notiv_toggle_context() {
	local context_name record target target_window
	context_name="$1"

	if notiv_popup_inside_session; then
		record="$(notiv_registry_resolve "$context_name")" || notiv_die "unknown context '$context_name'"
		target="$(notiv_session_ensure "$context_name" "$(notiv_record_field "$record" 2)" "$(notiv_record_field "$record" 3)")"
		target_window="${target#*:}"
		if [ "$(notiv_popup_current_window 2>/dev/null || true)" = "$target_window" ]; then
			notiv_close_context "$context_name"
		else
			notiv_popup_switch_context "$context_name" "$target"
		fi
		return 0
	fi

	notiv_open_context "$context_name"
}

notiv_close_context() {
	notiv_popup_close "$1"
}

notiv_toggle_main() {
	local subcommand context_name
	subcommand="${1:-toggle}"
	context_name="${2:-}"

	case "$subcommand" in
		toggle)
			[ -n "$context_name" ] || notiv_die "$subcommand requires a context name"
			notiv_toggle_context "$context_name"
			;;
		open)
			[ -n "$context_name" ] || notiv_die "$subcommand requires a context name"
			notiv_open_context "$context_name"
			;;
		close)
			[ -n "$context_name" ] || notiv_die "close requires a context name"
			notiv_close_context "$context_name"
			;;
		*)
			notiv_die "unknown toggle command: $subcommand"
			;;
	esac
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
	set -euo pipefail
	notiv_toggle_main "$@"
fi
