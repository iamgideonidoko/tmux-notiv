#!/usr/bin/env bash

if [ "${NOTIV_SCRIPT_MENU_SOURCED:-0}" = "1" ]; then
	return 0 2>/dev/null || exit 0
fi
NOTIV_SCRIPT_MENU_SOURCED=1

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
export NOTIV_ROOT="${NOTIV_ROOT:-$ROOT_DIR}"

# shellcheck source=../lib/popup.sh
. "$ROOT_DIR/lib/popup.sh"

notiv_menu_show() {
	local client

	client="$(notiv_popup_current_client 2>/dev/null || true)"
	[ -n "$client" ] || notiv_die "unable to determine tmux client for menu"

	if notiv_popup_inside_session; then
		tmux_cmd display-menu \
			-c "$client" \
			-T "notiv" \
			-x C -y C \
			"size down" "-" "run-shell \"$NOTIV_ROOT/notiv zoom in\"" \
			"size up" "+" "run-shell \"$NOTIV_ROOT/notiv zoom out\"" \
			"full screen" "f" "run-shell \"$NOTIV_ROOT/notiv zoom full\"" \
			"reset size" "r" "run-shell \"$NOTIV_ROOT/notiv zoom reset\"" \
			"embed in session" "e" "run-shell \"$NOTIV_ROOT/notiv embed\"" \
			"lock bindings" "d" "run-shell \"$NOTIV_ROOT/notiv zoom lock\"" >/dev/null
	else
		tmux_cmd display-menu \
			-c "$client" \
			-T "notiv" \
			-x C -y C \
			"pop current window" "p" "run-shell \"$NOTIV_ROOT/notiv embed pop\"" >/dev/null
	fi
}

notiv_menu_main() {
	notiv_menu_show
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
	set -euo pipefail
	notiv_menu_main "$@"
fi
