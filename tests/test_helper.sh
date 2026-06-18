#!/usr/bin/env bash
set -euo pipefail

TEST_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
export NOTIV_ROOT="$(CDPATH= cd -- "$TEST_DIR/.." && pwd)"
export TMUX_CMD_MOCK=1
export HOME="${HOME:-$TEST_DIR/home}"

TEST_TMP_DIR=""
MOCK_TMUX_LOG=""
MOCK_TMUX_OPTIONS_FILE=""
MOCK_TMUX_SESSIONS_FILE=""
MOCK_TMUX_BINDINGS_FILE=""
MOCK_CURRENT_CLIENT="client-1"

test_setup() {
	TEST_TMP_DIR="$(mktemp -d)"
	MOCK_TMUX_LOG="$TEST_TMP_DIR/tmux.log"
	MOCK_TMUX_OPTIONS_FILE="$TEST_TMP_DIR/options.txt"
	MOCK_TMUX_SESSIONS_FILE="$TEST_TMP_DIR/sessions.txt"
	MOCK_TMUX_BINDINGS_FILE="$TEST_TMP_DIR/bindings.txt"
	: >"$MOCK_TMUX_LOG"
	: >"$MOCK_TMUX_OPTIONS_FILE"
	: >"$MOCK_TMUX_SESSIONS_FILE"
	: >"$MOCK_TMUX_BINDINGS_FILE"
	MOCK_CURRENT_CLIENT="client-1"
}

test_teardown() {
	if [ -n "${TEST_TMP_DIR:-}" ] && [ -d "${TEST_TMP_DIR:-}" ]; then
		rm -rf "$TEST_TMP_DIR"
	fi
}

mock_log_tmux() {
	printf '%s\n' "$*" >>"$MOCK_TMUX_LOG"
}

mock_option_get() {
	local key line value
	key="$1"
	value=""

	while IFS= read -r line; do
		case "$line" in
			"$key="*)
				value="${line#"$key="}"
				;;
		esac
	done <"$MOCK_TMUX_OPTIONS_FILE"

	printf '%s\n' "$value"
}

mock_option_set() {
	local key value temp_file line
	key="$1"
	value="$2"
	temp_file="$TEST_TMP_DIR/options.tmp"
	: >"$temp_file"

	while IFS= read -r line; do
		case "$line" in
			"$key="*)
				;;
			*)
				printf '%s\n' "$line" >>"$temp_file"
				;;
		esac
	done <"$MOCK_TMUX_OPTIONS_FILE"

	printf '%s=%s\n' "$key" "$value" >>"$temp_file"
	mv "$temp_file" "$MOCK_TMUX_OPTIONS_FILE"
}

mock_session_exists() {
	local session_name line
	session_name="$1"

	while IFS= read -r line; do
		if [ "$line" = "$session_name" ]; then
			return 0
		fi
	done <"$MOCK_TMUX_SESSIONS_FILE"

	return 1
}

mock_session_add() {
	local session_name
	session_name="$1"
	if ! mock_session_exists "$session_name"; then
		printf '%s\n' "$session_name" >>"$MOCK_TMUX_SESSIONS_FILE"
	fi
}

mock_options_dump() {
	local line
	while IFS= read -r line; do
		[ -n "$line" ] || continue
		printf '%s %s\n' "${line%%=*}" "${line#*=}"
	done <"$MOCK_TMUX_OPTIONS_FILE"
}

mock_binding_set() {
	local table key command temp_file line
	table="$1"
	key="$2"
	command="$3"
	temp_file="$TEST_TMP_DIR/bindings.tmp"
	: >"$temp_file"

	while IFS= read -r line; do
		case "$line" in
			"$table|$key|"*)
				;;
			*)
				printf '%s\n' "$line" >>"$temp_file"
				;;
		esac
	done <"$MOCK_TMUX_BINDINGS_FILE"

	printf '%s|%s|%s\n' "$table" "$key" "$command" >>"$temp_file"
	mv "$temp_file" "$MOCK_TMUX_BINDINGS_FILE"
}

mock_binding_unset() {
	local table key temp_file line
	table="$1"
	key="$2"
	temp_file="$TEST_TMP_DIR/bindings.tmp"
	: >"$temp_file"

	while IFS= read -r line; do
		case "$line" in
			"$table|$key|"*)
				;;
			*)
				printf '%s\n' "$line" >>"$temp_file"
				;;
		esac
	done <"$MOCK_TMUX_BINDINGS_FILE"

	mv "$temp_file" "$MOCK_TMUX_BINDINGS_FILE"
}

mock_binding_count() {
	local table key count line
	table="$1"
	key="$2"
	count=0

	while IFS= read -r line; do
		case "$line" in
			"$table|$key|"*)
				count=$((count + 1))
				;;
		esac
	done <"$MOCK_TMUX_BINDINGS_FILE"

	printf '%s\n' "$count"
}

mock_binding_command() {
	local table key line
	table="$1"
	key="$2"

	while IFS= read -r line; do
		case "$line" in
			"$table|$key|"*)
				printf '%s\n' "${line#"$table|$key|"}"
				return 0
				;;
		esac
	done <"$MOCK_TMUX_BINDINGS_FILE"

	return 1
}

notiv_tmux_cmd_mock() {
	local command_name
	command_name="$1"
	shift || true
	mock_log_tmux "$command_name $*"

	case "$command_name" in
		show-option)
			if [ "$1" = "-gqv" ]; then
				mock_option_get "$2"
				return 0
			fi
			;;
		show-options)
			if [ "$1" = "-g" ]; then
				mock_options_dump
				return 0
			fi
			;;
		set-option)
			if [ "$1" = "-gq" ]; then
				mock_option_set "$2" "$3"
				return 0
			fi
			;;
		has-session)
			if [ "$1" = "-t" ] && mock_session_exists "$2"; then
				return 0
			fi
			return 1
			;;
		new-session)
			local session_name dir cmd arg
			session_name=""
			dir=""
			cmd=""
			while [ "$#" -gt 0 ]; do
				arg="$1"
				shift || true
				case "$arg" in
					-d)
						;;
					-s)
						session_name="$1"
						shift || true
						;;
					-c)
						dir="$1"
						shift || true
						;;
					*)
						cmd="$arg"
						break
						;;
				esac
			done
			mock_session_add "$session_name"
			printf '%s|%s|%s\n' "$session_name" "$dir" "$cmd" >>"$TEST_TMP_DIR/new-sessions.log"
			return 0
			;;
		display-popup)
			printf '%s\n' "$*" >>"$TEST_TMP_DIR/display-popup.log"
			return 0
			;;
		display-message)
			if [ "$1" = "-p" ] && [ "$2" = '#{client_name}' ]; then
				printf '%s\n' "$MOCK_CURRENT_CLIENT"
				return 0
			fi
			if [ "$1" = "-p" ]; then
				printf '%s\n' "$2"
				return 0
			fi
			return 1
			;;
		bind-key)
			local table key command
			table="prefix"
			if [ "$1" = "-T" ]; then
				table="$2"
				key="$3"
				shift 3 || true
			else
				key="$1"
				shift || true
			fi
			command="$*"
			mock_binding_set "$table" "$key" "$command"
			return 0
			;;
		unbind-key)
			local table key
			table="prefix"
			if [ "$1" = "-T" ]; then
				table="$2"
				key="$3"
			else
				key="$1"
			fi
			mock_binding_unset "$table" "$key"
			return 0
			;;
		display-menu)
			printf '%s\n' "$*" >>"$TEST_TMP_DIR/display-menu.log"
			return 0
			;;
	esac

	printf 'unsupported mock tmux command: %s %s\n' "$command_name" "$*" >&2
	return 1
}

assert_eq() {
	local expected actual message
	expected="$1"
	actual="$2"
	message="$3"

	if [ "$expected" != "$actual" ]; then
		printf 'assert_eq failed: %s\nexpected: %s\nactual: %s\n' "$message" "$expected" "$actual" >&2
		exit 1
	fi
}

assert_contains() {
	local needle haystack message
	needle="$1"
	haystack="$2"
	message="$3"

	case "$haystack" in
		*"$needle"*)
			;;
		*)
			printf 'assert_contains failed: %s\nneedle: %s\nhaystack: %s\n' "$message" "$needle" "$haystack" >&2
			exit 1
			;;
	esac
}

assert_file_contains() {
	local needle file_path message
	needle="$1"
	file_path="$2"
	message="$3"

	if ! grep -F -- "$needle" "$file_path" >/dev/null 2>&1; then
		printf 'assert_file_contains failed: %s\nneedle: %s\nfile: %s\n' "$message" "$needle" "$file_path" >&2
		exit 1
	fi
}

assert_file_line_count() {
	local expected needle file_path message actual
	expected="$1"
	needle="$2"
	file_path="$3"
	message="$4"
	actual="$(grep -F -c -- "$needle" "$file_path" 2>/dev/null || true)"
	assert_eq "$expected" "$actual" "$message"
}

# shellcheck source=../scripts/toggle.sh
. "$NOTIV_ROOT/scripts/toggle.sh"
