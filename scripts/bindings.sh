#!/usr/bin/env bash

if [ "${NOTIV_SCRIPT_BINDINGS_SOURCED:-0}" = "1" ]; then
	return 0 2>/dev/null || exit 0
fi
NOTIV_SCRIPT_BINDINGS_SOURCED=1

# shellcheck source=./registry.sh
. "$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/registry.sh"

notiv_config_key_notes() {
	notiv_get_option "@notiv_key_notes" "n"
}

notiv_config_key_todo() {
	notiv_get_option "@notiv_key_todo" "t"
}

notiv_config_key_git() {
	notiv_get_option "@notiv_key_git" "g"
}

notiv_config_key_list() {
	notiv_get_option "@notiv_key_list" "l"
}

notiv_config_key_picker() {
	notiv_get_option "@notiv_key_picker" "p"
}

notiv_bindings_cli_command() {
	local action context_name command_string
	action="$1"
	context_name="${2:-}"

	if [ -n "$context_name" ]; then
		printf -v command_string '%q %q %q' "$NOTIV_ROOT/notiv" "$action" "$context_name"
	else
		printf -v command_string '%q %q' "$NOTIV_ROOT/notiv" "$action"
	fi

	printf '%s\n' "$command_string"
}

notiv_bindings_record_key() {
	local csv key
	csv="${1:-}"
	key="$2"
	notiv_csv_append_unique "$csv" "$key"
}

notiv_bindings_current_keys() {
	local keys
	keys=""
	keys="$(notiv_bindings_record_key "$keys" "$(notiv_config_key_notes)")"
	keys="$(notiv_bindings_record_key "$keys" "$(notiv_config_key_todo)")"
	keys="$(notiv_bindings_record_key "$keys" "$(notiv_config_key_git)")"
	keys="$(notiv_bindings_record_key "$keys" "$(notiv_config_key_list)")"
	keys="$(notiv_bindings_record_key "$keys" "$(notiv_config_key_picker)")"
	printf '%s\n' "$keys"
}

notiv_bindings_clear() {
	local cached_keys current_keys all_keys old_ifs key
	cached_keys="$(notiv_get_option "@notiv_bound_keys" "")"
	current_keys="$(notiv_bindings_current_keys)"
	all_keys="$cached_keys"

	old_ifs="$IFS"
	IFS=','
	for key in $current_keys; do
		key="$(notiv_trim "$key")"
		[ -n "$key" ] || continue
		all_keys="$(notiv_csv_append_unique "$all_keys" "$key")"
	done
	IFS="$old_ifs"

	tmux_cmd unbind-key -T prefix n >/dev/null 2>&1 || true

	IFS=','
	for key in $all_keys; do
		key="$(notiv_trim "$key")"
		[ -n "$key" ] || continue
		tmux_cmd unbind-key -T notiv "$key" >/dev/null 2>&1 || true
	done
	IFS="$old_ifs"

	notiv_set_option "@notiv_bound_keys" ""
}

notiv_bindings_bind_context() {
	local context_name key shell_command
	context_name="$1"
	key="$2"

	if ! notiv_registry_resolve "$context_name" >/dev/null 2>&1; then
		return 1
	fi

	shell_command="$(notiv_bindings_cli_command "toggle" "$context_name")"
	tmux_cmd bind-key -T notiv "$key" run-shell "$shell_command" >/dev/null
	return 0
}

notiv_bindings_bind_action() {
	local key action shell_command
	key="$1"
	action="$2"
	shell_command="$(notiv_bindings_cli_command "$action")"
	tmux_cmd bind-key -T notiv "$key" run-shell "$shell_command" >/dev/null
}

notiv_bindings() {
	local bound_keys notes_key todo_key git_key list_key picker_key
	bound_keys=""
	notes_key="$(notiv_config_key_notes)"
	todo_key="$(notiv_config_key_todo)"
	git_key="$(notiv_config_key_git)"
	list_key="$(notiv_config_key_list)"
	picker_key="$(notiv_config_key_picker)"

	notiv_bindings_clear
	tmux_cmd bind-key -T prefix n switch-client -T notiv >/dev/null

	if notiv_bindings_bind_context "notes" "$notes_key"; then
		bound_keys="$(notiv_bindings_record_key "$bound_keys" "$notes_key")"
	fi
	if notiv_bindings_bind_context "todo" "$todo_key"; then
		bound_keys="$(notiv_bindings_record_key "$bound_keys" "$todo_key")"
	fi
	if notiv_bindings_bind_context "git" "$git_key"; then
		bound_keys="$(notiv_bindings_record_key "$bound_keys" "$git_key")"
	fi

	notiv_bindings_bind_action "$list_key" "list"
	bound_keys="$(notiv_bindings_record_key "$bound_keys" "$list_key")"

	if [ -n "$(notiv_registry_names)" ]; then
		notiv_bindings_bind_action "$picker_key" "picker"
		bound_keys="$(notiv_bindings_record_key "$bound_keys" "$picker_key")"
	fi

	notiv_set_option "@notiv_bound_keys" "$bound_keys"
}

notiv_bindings_main() {
	local subcommand
	subcommand="${1:-load}"

	case "$subcommand" in
		load|reload)
			notiv_bindings
			;;
		clear)
			notiv_bindings_clear
			;;
		*)
			notiv_die "unknown bindings command: $subcommand"
			;;
	esac
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
	set -euo pipefail
	notiv_bindings_main "$@"
fi
