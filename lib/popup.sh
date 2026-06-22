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

notiv_popup_current_session() {
	tmux_cmd display-message -p '#{session_name}'
}

notiv_popup_current_window() {
	tmux_cmd display-message -p '#{window_name}'
}

notiv_popup_inside_session() {
	[ "$(notiv_popup_current_session 2>/dev/null || true)" = "$(notiv_session_name)" ]
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
	local context_name dir target width height client title attach_cmd
	context_name="$1"
	dir="$2"
	target="$3"
	width="$4"
	height="$5"
	client="$(notiv_popup_target_client "$context_name")" || notiv_die "unable to determine tmux client for context '$context_name'"
	title="notiv:${context_name}"
	printf -v attach_cmd 'exec %q attach-session -t %q' "${NOTIV_TMUX_BIN:-tmux}" "$target"

	tmux_cmd display-popup \
		-c "$client" \
		-d "$dir" \
		-x C \
		-y C \
		-w "$width" \
		-h "$height" \
		-T "$title" \
		-E \
		"$attach_cmd" >/dev/null

	notiv_state_set_popup_client "$context_name" "$client"
	notiv_state_set_last_context "$context_name"
	notiv_state_set_client_active_context "$client" "$context_name"
}

notiv_popup_switch_context() {
	local context_name target
	context_name="$1"
	target="$2"

	if ! notiv_popup_inside_session; then
		notiv_die "cannot switch context outside the notiv session"
	fi

	tmux_cmd select-window -t "$target" >/dev/null
	notiv_state_set_last_context "$context_name"
}

notiv_popup_close() {
	local context_name client
	context_name="$1"

	if notiv_popup_inside_session; then
		client="$(notiv_state_get_popup_client "$context_name")"
		if [ -n "$client" ]; then
			notiv_state_clear_client_active_context "$client"
		fi
		notiv_state_clear_popup_client "$context_name"
		tmux_cmd detach-client >/dev/null
		return 0
	fi

	client="$(notiv_popup_target_client "$context_name")" || notiv_die "unable to determine tmux client for context '$context_name'"
	tmux_cmd display-popup -C -c "$client" >/dev/null
	notiv_state_clear_popup_client "$context_name"
	notiv_state_clear_client_active_context "$client"
}
