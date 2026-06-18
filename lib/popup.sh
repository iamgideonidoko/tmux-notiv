#!/usr/bin/env bash

if [ "${NOTIV_LIB_POPUP_SOURCED:-0}" = "1" ]; then
	return 0 2>/dev/null || exit 0
fi
NOTIV_LIB_POPUP_SOURCED=1

# shellcheck source=./state.sh
. "$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/state.sh"

notiv_popup_current_client() {
	tmux_cmd display-message -p '#{client_name}'
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

notiv_popup_open() {
	local context_name dir session_name width height client title attach_cmd
	context_name="$1"
	dir="$2"
	session_name="$3"
	width="$4"
	height="$5"
	client="$(notiv_popup_target_client "$context_name")" || notiv_die "unable to determine tmux client for context '$context_name'"
	title="notiv:${context_name}"
	printf -v attach_cmd 'exec %q attach-session -t %q' "${NOTIV_TMUX_BIN:-tmux}" "$session_name"

	tmux_cmd display-popup \
		-c "$client" \
		-d "$dir" \
		-x C \
		-y C \
		-w "$width" \
		-h "$height" \
		-T "$title" \
		"$attach_cmd" >/dev/null

	notiv_state_set_popup_client "$context_name" "$client"
	notiv_state_set_last_context "$context_name"
}

notiv_popup_close() {
	local context_name client
	context_name="$1"
	client="$(notiv_popup_target_client "$context_name")" || notiv_die "unable to determine tmux client for context '$context_name'"

	tmux_cmd display-popup -C -c "$client" >/dev/null
	notiv_state_clear_popup_client "$context_name"
}
