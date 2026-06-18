#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=./toggle.sh
. "$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/toggle.sh"

notiv_cli_usage() {
	cat <<'EOF'
Usage:
  notiv toggle <name>
  notiv open <name>
  notiv close <name>
  notiv list
  notiv reload
EOF
}

notiv_cli_list() {
	local record
	printf 'name\tdir\tcmd\twidth\theight\n'
	while IFS= read -r record; do
		[ -n "$record" ] || continue
		printf '%s\n' "$record"
	done <<EOF
$(notiv_registry_list)
EOF
}

notiv_cli_main() {
	local command_name context_name
	command_name="${1:-}"

	case "$command_name" in
		toggle)
			context_name="${2:-}"
			[ -n "$context_name" ] || notiv_die "toggle requires a context name"
			notiv_toggle_context "$context_name"
			;;
		open)
			context_name="${2:-}"
			[ -n "$context_name" ] || notiv_die "open requires a context name"
			notiv_open_context "$context_name"
			;;
		close)
			context_name="${2:-}"
			[ -n "$context_name" ] || notiv_die "close requires a context name"
			notiv_close_context "$context_name"
			;;
		list)
			notiv_cli_list
			;;
		reload)
			notiv_registry_reload >/dev/null
			;;
		help|-h|--help|"")
			notiv_cli_usage
			;;
		*)
			notiv_die "unknown command: $command_name"
			;;
	esac
}

notiv_cli_main "$@"
