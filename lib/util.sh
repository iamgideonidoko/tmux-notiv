#!/usr/bin/env bash

if [ "${NOTIV_LIB_UTIL_SOURCED:-0}" = "1" ]; then
	return 0 2>/dev/null || exit 0
fi
NOTIV_LIB_UTIL_SOURCED=1

notiv_root_dir() {
	local source_dir
	source_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
	CDPATH= cd -- "$source_dir/.." && pwd
}

NOTIV_ROOT="${NOTIV_ROOT:-$(notiv_root_dir)}"

notiv_die() {
	printf 'notiv: %s\n' "$*" >&2
	exit 1
}

notiv_warn() {
	printf 'notiv: %s\n' "$*" >&2
}

notiv_trim() {
	local value
	value="$1"
	value="${value#"${value%%[![:space:]]*}"}"
	value="${value%"${value##*[![:space:]]}"}"
	printf '%s' "$value"
}

notiv_expand_path() {
	local path
	path="$1"

	case "$path" in
		"")
			printf '\n'
			;;
		\~)
			printf '%s\n' "$HOME"
			;;
		\~/*)
			printf '%s/%s\n' "$HOME" "${path#\~/}"
			;;
		*)
			printf '%s\n' "$path"
			;;
	esac
}

notiv_sanitize_name() {
	printf '%s' "$1" | tr -c '[:alnum:]_-' '_'
}

notiv_context_option_key() {
	local name field
	name="$(notiv_sanitize_name "$1")"
	field="$2"
	printf '@notiv_%s_%s\n' "$name" "$field"
}

notiv_window_name() {
	printf '%s\n' "$(notiv_sanitize_name "$1")"
}

notiv_env_get() {
	local line
	line="$(tmux_cmd showenv -g "$1" 2>/dev/null || true)"
	case "$line" in
		"$1="*)
			printf '%s\n' "${line#"$1="}"
			;;
		*)
			printf '\n'
			;;
	esac
}

notiv_env_set() {
	tmux_cmd setenv -g "$1" "$2" >/dev/null 2>&1 || true
}

notiv_env_clear() {
	tmux_cmd setenv -gu "$1" >/dev/null 2>&1 || true
}

notiv_env_clear_width_height() {
	notiv_env_clear NOTIV_WIDTH
	notiv_env_clear NOTIV_HEIGHT
}

notiv_popup_default_title() {
	local context_name
	context_name="$1"
	printf 'notiv:%s  C-M-s -  C-M-b +  C-M-f full  C-M-r reset  C-M-e embed  C-M-d lock' "$context_name"
}

notiv_popup_locked_title() {
	local context_name
	context_name="$1"
	printf 'notiv:%s  Bindings locked. Unlock with C-M-u' "$context_name"
}

notiv_csv_contains() {
	local csv needle
	csv="${1:-}"
	needle="$2"

	case ",$csv," in
		*,"$needle",*)
			return 0
			;;
		*)
			return 1
			;;
	esac
}

notiv_csv_append_unique() {
	local csv needle
	csv="${1:-}"
	needle="$2"

	if [ -z "$needle" ]; then
		printf '%s\n' "$csv"
		return 0
	fi

	if notiv_csv_contains "$csv" "$needle"; then
		printf '%s\n' "$csv"
		return 0
	fi

	if [ -z "$csv" ]; then
		printf '%s\n' "$needle"
	else
		printf '%s,%s\n' "$csv" "$needle"
	fi
}

notiv_record_field() {
	local record index old_ifs field current
	record="$1"
	index="$2"
	old_ifs="$IFS"
	IFS='	'
	current=1
	for field in $record; do
		if [ "$current" -eq "$index" ]; then
			IFS="$old_ifs"
			printf '%s\n' "$field"
			return 0
		fi
		current=$((current + 1))
	done
	IFS="$old_ifs"
	return 1
}
