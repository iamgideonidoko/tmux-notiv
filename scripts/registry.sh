#!/usr/bin/env bash

if [ "${NOTIV_SCRIPT_REGISTRY_SOURCED:-0}" = "1" ]; then
	return 0 2>/dev/null || exit 0
fi
NOTIV_SCRIPT_REGISTRY_SOURCED=1

# shellcheck source=./config.sh
. "$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/config.sh"

notiv_registry_names() {
	local names auto_register old_ifs entry entry_name option_lines line option_name context_name
	names=""
	auto_register="$(notiv_config_auto_register)"

	if [ -n "$auto_register" ]; then
		old_ifs="$IFS"
		IFS=','
		for entry in $auto_register; do
			entry="$(notiv_trim "$entry")"
			[ -n "$entry" ] || continue

			IFS=':' read -r entry_name _ <<EOF
$entry
EOF
			entry_name="$(notiv_trim "$entry_name")"
			if [ -n "$entry_name" ]; then
				names="$(notiv_csv_append_unique "$names" "$entry_name")"
			fi
		done
		IFS="$old_ifs"
	fi

	option_lines="$(notiv_config_list_option_lines)"
	while IFS= read -r line; do
		case "$line" in
			@notiv_*_dir\ *)
				option_name="${line%% *}"
				context_name="${option_name#@notiv_}"
				context_name="${context_name%_dir}"
				names="$(notiv_csv_append_unique "$names" "$context_name")"
				;;
		esac
	done <<EOF
$option_lines
EOF

	printf '%s\n' "$names"
}

notiv_registry_resolve() {
	local target_name auto_register old_ifs entry entry_name entry_dir entry_cmd entry_width entry_height entry_key extra
	local dir cmd width height key
	target_name="$1"
	dir=""
	cmd=""
	width=""
	height=""
	key=""
	auto_register="$(notiv_config_auto_register)"

	if [ -n "$auto_register" ]; then
		old_ifs="$IFS"
		IFS=','
		for entry in $auto_register; do
			entry="$(notiv_trim "$entry")"
			[ -n "$entry" ] || continue

			IFS=':' read -r entry_name entry_dir entry_cmd entry_width entry_height entry_key extra <<EOF
$entry
EOF

			if [ "$(notiv_trim "$entry_name")" = "$target_name" ]; then
				dir="$(notiv_trim "$entry_dir")"
				cmd="$(notiv_trim "$entry_cmd")"
				width="$(notiv_trim "$entry_width")"
				height="$(notiv_trim "$entry_height")"
				key="$(notiv_trim "$entry_key")"
				break
			fi
		done
		IFS="$old_ifs"
	fi

	if [ -n "$(notiv_config_context_dir "$target_name")" ]; then
		dir="$(notiv_config_context_dir "$target_name")"
	fi
	if [ -n "$(notiv_config_context_cmd "$target_name")" ]; then
		cmd="$(notiv_config_context_cmd "$target_name")"
	fi
	if [ -n "$(notiv_config_context_width "$target_name")" ]; then
		width="$(notiv_config_context_width "$target_name")"
	fi
	if [ -n "$(notiv_config_context_height "$target_name")" ]; then
		height="$(notiv_config_context_height "$target_name")"
	fi
	if [ -n "$(notiv_config_context_key "$target_name")" ]; then
		key="$(notiv_config_context_key "$target_name")"
	fi

	dir="$(notiv_expand_tmux_format "$dir")"
	cmd="$(notiv_expand_tmux_format "$cmd")"
	width="$(notiv_expand_tmux_format "$width")"
	height="$(notiv_expand_tmux_format "$height")"
	key="$(notiv_expand_tmux_format "$key")"
	dir="$(notiv_expand_path "$dir")"
	[ -n "$dir" ] || return 1

	if [ -z "$cmd" ]; then
		cmd="$(notiv_config_default_cmd)"
	fi
	if [ -z "$width" ]; then
		width="$(notiv_config_popup_width)"
	fi
	if [ -z "$height" ]; then
		height="$(notiv_config_popup_height)"
	fi

	printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$target_name" "$dir" "$cmd" "$width" "$height" "$key"
}

notiv_registry_list() {
	local names old_ifs name record
	names="$(notiv_registry_names)"
	[ -n "$names" ] || return 0

	old_ifs="$IFS"
	IFS=','
	for name in $names; do
		record="$(notiv_registry_resolve "$name")" || continue
		printf '%s\n' "$record"
	done
	IFS="$old_ifs"
}

notiv_registry_reload() {
	local names
	names="$(notiv_registry_names)"
	notiv_set_option "@notiv_registered_contexts" "$names"
	printf '%s\n' "$names"
}

notiv_registry_main() {
	local subcommand name
	subcommand="${1:-list}"

	case "$subcommand" in
		list)
			notiv_registry_list
			;;
		resolve)
			name="${2:-}"
			[ -n "$name" ] || notiv_die "registry resolve requires a context name"
			notiv_registry_resolve "$name"
			;;
		reload)
			notiv_registry_reload
			;;
		names)
			notiv_registry_names
			;;
		*)
			notiv_die "unknown registry command: $subcommand"
			;;
	esac
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
	set -euo pipefail
	notiv_registry_main "$@"
fi
