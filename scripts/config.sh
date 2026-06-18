#!/usr/bin/env bash

if [ "${NOTIV_SCRIPT_CONFIG_SOURCED:-0}" = "1" ]; then
	return 0 2>/dev/null || exit 0
fi
NOTIV_SCRIPT_CONFIG_SOURCED=1

# shellcheck source=../lib/state.sh
. "$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/lib/state.sh"

notiv_config_default_cmd() {
	notiv_get_option "@notiv_default_cmd" "nvim"
}

notiv_config_popup_width() {
	notiv_get_option "@notiv_popup_width" "90%"
}

notiv_config_popup_height() {
	notiv_get_option "@notiv_popup_height" "90%"
}

notiv_config_auto_register() {
	notiv_get_option "@notiv_auto_register" ""
}

notiv_config_context_dir() {
	notiv_get_option "$(notiv_context_option_key "$1" "dir")" ""
}

notiv_config_context_cmd() {
	notiv_get_option "$(notiv_context_option_key "$1" "cmd")" ""
}

notiv_config_context_width() {
	notiv_get_option "$(notiv_context_option_key "$1" "width")" ""
}

notiv_config_context_height() {
	notiv_get_option "$(notiv_context_option_key "$1" "height")" ""
}

notiv_config_context_key() {
	notiv_get_option "$(notiv_context_option_key "$1" "key")" ""
}

notiv_config_list_option_lines() {
	tmux_cmd show-options -g 2>/dev/null || true
}

notiv_config_main() {
	local subcommand
	subcommand="${1:-show}"

	case "$subcommand" in
		show)
			printf 'default_cmd=%s\n' "$(notiv_config_default_cmd)"
			printf 'popup_width=%s\n' "$(notiv_config_popup_width)"
			printf 'popup_height=%s\n' "$(notiv_config_popup_height)"
			printf 'auto_register=%s\n' "$(notiv_config_auto_register)"
			;;
		*)
			notiv_die "unknown config command: $subcommand"
			;;
	esac
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
	set -euo pipefail
	notiv_config_main "$@"
fi
