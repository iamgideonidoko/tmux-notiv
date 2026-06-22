#!/usr/bin/env bash

if [ "${NOTIV_LIB_POPUP_SOURCED:-0}" = "1" ]; then
	return 0 2>/dev/null || exit 0
fi
NOTIV_LIB_POPUP_SOURCED=1

# shellcheck source=../scripts/session.sh
. "$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/scripts/session.sh"

notiv_popup_current_client() {
	tmux_cmd display-message -p '#{client_name}'
}

notiv_popup_current_target() {
	tmux_cmd display-message -p '#{session_name}:#{window_name}'
}

notiv_popup_target_client() {
	local context_name current_client stored_client
	context_name="$1"
	current_client="$(notiv_popup_current_client 2>/dev/null || true)"

	if [ -n "$current_client" ]; then
		printf '%s\n' "$current_client"
		return 0
	fi

	stored_client="$(notiv_state_get_popup_client "$context_name")"
	if [ -n "$stored_client" ]; then
		printf '%s\n' "$stored_client"
		return 0
	fi

	return 1
}

notiv_popup_is_notiv_target() {
	local target
	target="$1"

	case "$target" in
		"$(notiv_session_name)":*)
			return 0
			;;
	esac

	return 1
}

notiv_popup_open() {
	local context_name target width height client current_target return_target
	context_name="$1"
	target="$3"
	width="$4"
	height="$5"
	client="$(notiv_popup_target_client "$context_name")" || notiv_die "unable to determine tmux client for context '$context_name'"
	current_target="$(notiv_popup_current_target 2>/dev/null || true)"

	if [ -n "$current_target" ] && ! notiv_popup_is_notiv_target "$current_target"; then
		notiv_state_set_client_return_target "$client" "$current_target"
	else
		return_target="$(notiv_state_get_client_return_target "$client")"
		if [ -z "$return_target" ] && [ -n "$current_target" ] && [ "$current_target" != "$target" ]; then
			notiv_state_set_client_return_target "$client" "$current_target"
		fi
	fi

	tmux_cmd switch-client -c "$client" -t "$target" >/dev/null

	notiv_state_set_popup_client "$context_name" "$client"
	notiv_state_set_last_context "$context_name"
}

notiv_popup_close() {
	local context_name client return_target
	context_name="$1"
	client="$(notiv_popup_target_client "$context_name")" || notiv_die "unable to determine tmux client for context '$context_name'"
	return_target="$(notiv_state_get_client_return_target "$client")"

	if [ -n "$return_target" ]; then
		tmux_cmd switch-client -c "$client" -t "$return_target" >/dev/null
		notiv_state_clear_client_return_target "$client"
	else
		tmux_cmd switch-client -c "$client" -l >/dev/null 2>&1 ||
			notiv_die "unable to determine where to close context '$context_name' for client '$client'"
	fi

	notiv_state_clear_popup_client "$context_name"
}
