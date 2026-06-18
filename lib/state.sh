#!/usr/bin/env bash

if [ "${NOTIV_LIB_STATE_SOURCED:-0}" = "1" ]; then
	return 0 2>/dev/null || exit 0
fi
NOTIV_LIB_STATE_SOURCED=1

# shellcheck source=./core.sh
. "$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/core.sh"

notiv_get_option() {
	local key default_value value
	key="$1"
	default_value="${2-}"
	value="$(tmux_cmd show-option -gqv "$key" 2>/dev/null || true)"

	if [ -n "$value" ]; then
		printf '%s\n' "$value"
	else
		printf '%s\n' "$default_value"
	fi
}

notiv_set_option() {
	local key value
	key="$1"
	value="$2"
	tmux_cmd set-option -gq "$key" "$value" >/dev/null
}

notiv_state_popup_client_key() {
	printf '@notiv_popup_%s_client\n' "$(notiv_sanitize_name "$1")"
}

notiv_state_get_popup_client() {
	notiv_get_option "$(notiv_state_popup_client_key "$1")" ""
}

notiv_state_set_popup_client() {
	notiv_set_option "$(notiv_state_popup_client_key "$1")" "$2"
}

notiv_state_clear_popup_client() {
	notiv_set_option "$(notiv_state_popup_client_key "$1")" ""
}

notiv_state_get_last_context() {
	notiv_get_option "@notiv_last_context" ""
}

notiv_state_set_last_context() {
	notiv_set_option "@notiv_last_context" "$1"
}
