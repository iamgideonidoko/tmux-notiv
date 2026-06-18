#!/usr/bin/env bash

if [ "${NOTIV_LIB_CORE_SOURCED:-0}" = "1" ]; then
	return 0 2>/dev/null || exit 0
fi
NOTIV_LIB_CORE_SOURCED=1

# shellcheck source=./util.sh
. "$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/util.sh"

tmux_cmd() {
	if [ "${TMUX_CMD_MOCK:-0}" = "1" ]; then
		if command -v notiv_tmux_cmd_mock >/dev/null 2>&1; then
			notiv_tmux_cmd_mock "$@"
			return $?
		fi
		notiv_die "TMUX_CMD_MOCK=1 but notiv_tmux_cmd_mock is not defined"
	fi

	if [ -n "${NOTIV_TMUX_SOCKET:-}" ]; then
		"${NOTIV_TMUX_BIN:-tmux}" -L "${NOTIV_TMUX_SOCKET}" "$@"
	else
		"${NOTIV_TMUX_BIN:-tmux}" "$@"
	fi
}

notiv_expand_tmux_format() {
	local value expanded
	value="$1"

	case "$value" in
		*"#{"*)
			expanded="$(tmux_cmd display-message -p "$value" 2>/dev/null || true)"
			if [ -n "$expanded" ]; then
				printf '%s\n' "$expanded"
			else
				printf '%s\n' "$value"
			fi
			;;
		*)
			printf '%s\n' "$value"
			;;
	esac
}
