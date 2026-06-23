#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=./toggle.sh
. "$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/toggle.sh"
# shellcheck source=./bindings.sh
. "$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/bindings.sh"

notiv_cli_usage() {
	cat <<'EOF'
Usage:
  notiv toggle <name>
  notiv open <name>
  notiv close <name>
  notiv menu
  notiv zoom <in|out|full|reset|lock|unlock>
  notiv embed [pop]
  notiv reload [bindings|registry]
EOF
}

notiv_cli_main() {
	local command_name context_name reload_target
	command_name="${1:-}"
	shift || true

	case "$command_name" in
		toggle)
			context_name="${1:-}"
			[ -n "$context_name" ] || notiv_die "toggle requires a context name"
			notiv_toggle_context "$context_name"
			;;
		open)
			context_name="${1:-}"
			[ -n "$context_name" ] || notiv_die "open requires a context name"
			notiv_open_context "$context_name"
			;;
		close)
			context_name="${1:-}"
			[ -n "$context_name" ] || notiv_die "close requires a context name"
			notiv_close_context "$context_name"
			;;
		menu)
			"$NOTIV_ROOT/scripts/menu.sh"
			;;
		zoom)
			"$NOTIV_ROOT/scripts/zoom.sh" "${1:-}"
			;;
		embed)
			"$NOTIV_ROOT/scripts/embed.sh" "${1:-embed}"
			;;
		reload)
			reload_target="${1:-all}"
			case "$reload_target" in
				all)
					notiv_registry_reload >/dev/null
					notiv_bindings
					;;
				bindings)
					notiv_bindings
					;;
				registry)
					notiv_registry_reload >/dev/null
					;;
				*)
					notiv_die "unknown reload target: $reload_target"
					;;
			esac
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
