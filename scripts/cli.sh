#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=./toggle.sh
. "$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/toggle.sh"
# shellcheck source=./bindings.sh
. "$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/bindings.sh"

notiv_cli_picker() {
	local names old_ifs name record client shortcut index shell_command
	names="$(notiv_registry_names)"

	if [ -z "$names" ]; then
		notiv_warn "no contexts registered"
		return 0
	fi

	client="$(tmux_cmd display-message -p '#{client_name}' 2>/dev/null || true)"
	[ -n "$client" ] || notiv_die "unable to determine tmux client for picker"

	set -- display-menu -c "$client" -T "notiv" -x C -y C
	index=1
	old_ifs="$IFS"
	IFS=','
	for name in $names; do
		record="$(notiv_registry_resolve "$name")" || continue
		case "$index" in
			10)
				shortcut="0"
				;;
			*)
				shortcut="$index"
				;;
		esac
		printf -v shell_command '%q %q %q' "$NOTIV_ROOT/notiv" "toggle" "$name"
		set -- "$@" "$name" "$shortcut" "run-shell $shell_command"
		index=$((index + 1))
	done
	IFS="$old_ifs"

	tmux_cmd "$@" >/dev/null
}

notiv_cli_usage() {
	cat <<'EOF'
Usage:
  notiv toggle <name>
  notiv open <name>
  notiv close <name>
  notiv picker
  notiv list
  notiv reload [bindings|registry]
EOF
}

notiv_cli_list() {
	local record
	printf 'name\tdir\tcmd\twidth\theight\tkey\n'
	while IFS= read -r record; do
		[ -n "$record" ] || continue
		printf '%s\n' "$record"
	done <<EOF
$(notiv_registry_list)
EOF
}

notiv_cli_main() {
	local command_name context_name reload_target
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
		picker)
			notiv_cli_picker
			;;
		list)
			notiv_cli_list
			;;
		reload)
			reload_target="${2:-all}"
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
