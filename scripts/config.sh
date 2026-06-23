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

notiv_config_session_name() {
	notiv_get_option "@notiv_session_name" "scratch-notiv"
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

notiv_config_border_color() {
	notiv_get_option "@notiv_border_color" "magenta"
}

notiv_config_text_color() {
	notiv_get_option "@notiv_text_color" "blue"
}

notiv_config_border_style() {
	notiv_get_option "@notiv_border_style" "rounded"
}

notiv_config_change_path() {
	notiv_get_option "@notiv_change_path" "true"
}

notiv_config_title() {
	notiv_get_option "@notiv_title" ""
}

notiv_config_key_menu() {
	notiv_get_option "@notiv_key_menu" "P"
}

notiv_config_key_prefix() {
	notiv_get_option "@notiv_key_prefix" "n"
}

notiv_config_root_bindings() {
	notiv_get_option "@notiv_root_bindings" "true"
}

notiv_config_key_zoom_in() {
	notiv_get_option "@notiv_key_zoom_in" "C-M-s"
}

notiv_config_key_zoom_out() {
	notiv_get_option "@notiv_key_zoom_out" "C-M-b"
}

notiv_config_key_fullscreen() {
	notiv_get_option "@notiv_key_fullscreen" "C-M-f"
}

notiv_config_key_reset() {
	notiv_get_option "@notiv_key_reset" "C-M-r"
}

notiv_config_key_embed() {
	notiv_get_option "@notiv_key_embed" "C-M-e"
}

notiv_config_key_lock() {
	notiv_get_option "@notiv_key_lock" "C-M-d"
}

notiv_config_key_unlock() {
	notiv_get_option "@notiv_key_unlock" "C-M-u"
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
			printf 'border_color=%s\n' "$(notiv_config_border_color)"
			printf 'text_color=%s\n' "$(notiv_config_text_color)"
			printf 'border_style=%s\n' "$(notiv_config_border_style)"
			printf 'change_path=%s\n' "$(notiv_config_change_path)"
			printf 'session_name=%s\n' "$(notiv_config_session_name)"
			printf 'key_prefix=%s\n' "$(notiv_config_key_prefix)"
			printf 'key_menu=%s\n' "$(notiv_config_key_menu)"
			printf 'root_bindings=%s\n' "$(notiv_config_root_bindings)"
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
