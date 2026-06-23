#!/usr/bin/env bash

if [ "${NOTIV_LIB_POPUP_SOURCED:-0}" = "1" ]; then
	return 0 2>/dev/null || exit 0
fi
NOTIV_LIB_POPUP_SOURCED=1

# shellcheck source=../scripts/session.sh
. "$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/scripts/session.sh"
# shellcheck source=../scripts/registry.sh
. "$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/scripts/registry.sh"
# shellcheck source=./util.sh
. "$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/util.sh"

notiv_popup_current_client() {
	tmux_cmd display-message -p '#{client_name}'
}

notiv_popup_current_session() {
	tmux_cmd display-message -p '#{session_name}'
}

notiv_popup_current_window() {
	tmux_cmd display-message -p '#{window_name}'
}

notiv_popup_current_path() {
	tmux_cmd display-message -p '#{pane_current_path}'
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

notiv_popup_title() {
	local context_name configured_title override
	context_name="$1"
	override="$(notiv_env_get NOTIV_TITLE_OVERRIDE)"
	if [ -n "$override" ]; then
		printf '%s\n' "$override"
		return 0
	fi
	configured_title="$(notiv_config_title)"
	if [ -n "$configured_title" ]; then
		printf '%s\n' "$configured_title"
	else
		notiv_popup_default_title "$context_name"
	fi
}

notiv_popup_set_root_bindings() {
	local root_bindings_enabled
	root_bindings_enabled="$(notiv_config_root_bindings)"
	[ "$root_bindings_enabled" = "true" ] || return 0

	if [ "$(notiv_get_option "@notiv_bindings_locked" "false")" = "true" ]; then
		tmux_cmd bind-key -n "$(notiv_config_key_unlock)" run-shell "$NOTIV_ROOT/notiv zoom unlock" >/dev/null 2>&1 || true
		return 0
	fi

	tmux_cmd bind-key -n "$(notiv_config_key_zoom_in)" run-shell "$NOTIV_ROOT/notiv zoom in" >/dev/null 2>&1 || true
	tmux_cmd bind-key -n "$(notiv_config_key_zoom_out)" run-shell "$NOTIV_ROOT/notiv zoom out" >/dev/null 2>&1 || true
	tmux_cmd bind-key -n "$(notiv_config_key_fullscreen)" run-shell "$NOTIV_ROOT/notiv zoom full" >/dev/null 2>&1 || true
	tmux_cmd bind-key -n "$(notiv_config_key_reset)" run-shell "$NOTIV_ROOT/notiv zoom reset" >/dev/null 2>&1 || true
	tmux_cmd bind-key -n "$(notiv_config_key_embed)" run-shell "$NOTIV_ROOT/notiv embed" >/dev/null 2>&1 || true
	tmux_cmd bind-key -n "$(notiv_config_key_lock)" run-shell "$NOTIV_ROOT/notiv zoom lock" >/dev/null 2>&1 || true
	tmux_cmd bind-key -n "$(notiv_config_key_unlock)" run-shell "$NOTIV_ROOT/notiv zoom unlock" >/dev/null 2>&1 || true
}

notiv_popup_unset_root_bindings() {
	tmux_cmd unbind-key -n "$(notiv_config_key_zoom_in)" >/dev/null 2>&1 || true
	tmux_cmd unbind-key -n "$(notiv_config_key_zoom_out)" >/dev/null 2>&1 || true
	tmux_cmd unbind-key -n "$(notiv_config_key_fullscreen)" >/dev/null 2>&1 || true
	tmux_cmd unbind-key -n "$(notiv_config_key_reset)" >/dev/null 2>&1 || true
	tmux_cmd unbind-key -n "$(notiv_config_key_embed)" >/dev/null 2>&1 || true
	tmux_cmd unbind-key -n "$(notiv_config_key_lock)" >/dev/null 2>&1 || true
	tmux_cmd unbind-key -n "$(notiv_config_key_unlock)" >/dev/null 2>&1 || true
}

notiv_popup_lock_root_bindings() {
	local unlock_key
	unlock_key="$(notiv_config_key_unlock)"

	notiv_popup_unset_root_bindings
	tmux_cmd bind-key -n "$unlock_key" run-shell "$NOTIV_ROOT/notiv zoom unlock" >/dev/null 2>&1 || true
}

notiv_popup_unlock_root_bindings() {
	notiv_popup_set_root_bindings
}

notiv_popup_sync_path() {
	local context_name target origin_session origin_path pane_command
	context_name="$1"
	target="$2"

	[ "$(notiv_config_change_path)" = "true" ] || return 0

	origin_session="$(notiv_state_get_origin_session "$(notiv_popup_current_client 2>/dev/null || true)")"
	[ -n "$origin_session" ] || return 0

	origin_path="$(tmux_cmd display-message -p -t "$origin_session" '#{pane_current_path}' 2>/dev/null || true)"
	[ -n "$origin_path" ] || return 0

	pane_command="$(tmux_cmd display-message -p -t "$target" '#{pane_current_command}' 2>/dev/null || true)"
	case "$pane_command" in
		sh|bash|zsh|fish|dash|ksh|csh|tcsh)
			tmux_cmd send-keys -R -t "$target" "cd \"$origin_path\"" C-m >/dev/null 2>&1 || true
			;;
	esac
}

notiv_popup_open() {
	local context_name dir target width height client title attach_cmd border_color text_color border_style
	local env_width env_height current_session
	context_name="$1"
	dir="$2"
	target="$3"
	width="$4"
	height="$5"
	client="$(notiv_popup_target_client "$context_name")" || notiv_die "unable to determine tmux client for context '$context_name'"

	current_session="$(notiv_popup_current_session 2>/dev/null || true)"
	if [ -n "$current_session" ] && [ "$current_session" != "$(notiv_session_name)" ]; then
		notiv_state_set_origin_session "$client" "$current_session"
	fi

	env_width="$(notiv_env_get NOTIV_WIDTH)"
	env_height="$(notiv_env_get NOTIV_HEIGHT)"
	[ -n "$env_width" ] && width="$env_width"
	[ -n "$env_height" ] && height="$env_height"

	title="$(notiv_popup_title "$context_name")"
	border_color="$(notiv_config_border_color)"
	text_color="$(notiv_config_text_color)"
	border_style="$(notiv_config_border_style)"

	notiv_state_set_popup_client "$context_name" "$client"
	notiv_state_set_last_context "$context_name"
	notiv_state_set_client_active_context "$client" "$context_name"

	notiv_popup_sync_path "$context_name" "$target"
	notiv_popup_set_root_bindings

	printf -v attach_cmd 'exec %q attach-session -t %q' "${NOTIV_TMUX_BIN:-tmux}" "$target"

	tmux_cmd display-popup \
		-c "$client" \
		-S "fg=$border_color" \
		-s "fg=$text_color" \
		-b "$border_style" \
		-d "$dir" \
		-x C \
		-y C \
		-w "$width" \
		-h "$height" \
		-T "$title" \
		-E \
		"$attach_cmd" >/dev/null
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

	notiv_set_option "@notiv_bindings_locked" "false"
	notiv_env_clear NOTIV_TITLE_OVERRIDE

	if notiv_popup_inside_session; then
		client="$(notiv_state_get_popup_client "$context_name")"
		if [ -n "$client" ]; then
			notiv_state_clear_client_active_context "$client"
			notiv_state_clear_origin_session "$client"
		fi
		notiv_state_clear_popup_client "$context_name"
		notiv_popup_unset_root_bindings
		tmux_cmd detach-client >/dev/null
		return 0
	fi

	client="$(notiv_popup_target_client "$context_name")" || notiv_die "unable to determine tmux client for context '$context_name'"
	tmux_cmd display-popup -C -c "$client" >/dev/null
	notiv_state_clear_popup_client "$context_name"
	notiv_state_clear_client_active_context "$client"
	notiv_state_clear_origin_session "$client"
	notiv_popup_unset_root_bindings
}

notiv_popup_reopen() {
	local context_name record dir cmd target width height
	context_name="$(notiv_state_get_last_context)"
	[ -n "$context_name" ] || notiv_die "no active context to reopen"

	record="$(notiv_registry_resolve "$context_name")" || notiv_die "unknown context '$context_name'"
	dir="$(notiv_record_field "$record" 2)"
	cmd="$(notiv_record_field "$record" 3)"
	width="$(notiv_record_field "$record" 4)"
	height="$(notiv_record_field "$record" 5)"

	target="$(notiv_window_target "$context_name")"

	notiv_popup_open "$context_name" "$dir" "$target" "$width" "$height"
}
